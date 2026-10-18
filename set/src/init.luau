--!strict

--[=[
	@class Set

	A Luau implementation of JavaScript's
	[`Set`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set).

	An insertion-ordered collection of unique values. Any Luau value can be a
	member, including `nil`, `NaN`, and tables. Membership uses `SameValueZero`:
	`NaN` equals `NaN`, and `+0` equals `-0`.

	```lua
	local Set = require(path.to.Set)

	local s = Set.new({ 1, 2, 2, 3 })
	print(s.size) -- 3
	```

	:::note
	Methods take the set as their first argument, as in
	`Set.prototype.add(set, value)`, or as `set.add(set, value)`. `size` is a
	read-only property, provided through `__index`. `set.constructor` is `Set`,
	and `Object.prototype.toString` reports `"[object Set]"` through
	`Symbol.toStringTag`.
	:::

	:::caution
	Deleted members are kept as tombstones until `clear` is called. A set that
	adds and deletes values without calling `clear` grows without bound. `clear`
	releases the storage.
	:::

	:::caution
	The set-algebra methods (`union`, `intersection`, `difference`,
	`symmetricDifference`, `isSubsetOf`, `isSupersetOf`, `isDisjointFrom`) take a
	set-like argument: a table with a numeric `size`, and with `has` and `keys`
	methods. A `Set` is one.
	:::

	:::caution
	Iterators are not Luau generic-`for` iterators. Step them with
	`it.next(it)` in a `while` loop.
	:::

	:::note
	`Set` and its prototype table are frozen with `table.freeze`. Each instance
	stays mutable.
	:::
]=]

const Symbol = require "./Symbol"
const TypeError = require "./Error" .TypeError
const esTypes = require "./ES17-Types"
const iterate = require "./iterate"

--[=[
	@within Set
	@type Set<T> = { read size: number, add: ..., has: ..., delete: ..., clear: ..., forEach: ..., values: ..., keys: ..., entries: ..., union: ..., intersection: ..., difference: ..., symmetricDifference: ..., isSubsetOf: ..., isSupersetOf: ..., isDisjointFrom: ... }

	A set of values of type `T`. The fields are its methods, and `size` is a
	read-only count.
]=]
export type Set<T> = {
	read size: number,
	add: (self: Set<T>, value: T) -> Set<T>,
	has: (self: Set<T>, value: T) -> boolean,
	delete: (self: Set<T>, value: T) -> boolean,
	clear: (self: Set<T>) -> (),
	forEach: (self: Set<T>, callback: (value: T, value2: T, set: Set<T>) -> ()) -> (),
	values: (self: Set<T>) -> esTypes.Iterator<T>,
	keys: (self: Set<T>) -> esTypes.Iterator<T>,
	entries: (self: Set<T>) -> esTypes.Iterator<{ T }>,
	union: <U>(self: Set<T>, other: SetLike<U>) -> Set<T | U>,
	intersection: <U>(self: Set<T>, other: SetLike<U>) -> Set<T>,
	difference: <U>(self: Set<T>, other: SetLike<U>) -> Set<T>,
	symmetricDifference: <U>(self: Set<T>, other: SetLike<U>) -> Set<T | U>,
	isSubsetOf: <U>(self: Set<T>, other: SetLike<U>) -> boolean,
	isSupersetOf: <U>(self: Set<T>, other: SetLike<U>) -> boolean,
	isDisjointFrom: <U>(self: Set<T>, other: SetLike<U>) -> boolean,
}

--[=[
	@within Set
	@type SetLike<T> = { read size: number, has: (self: any, value: T) -> boolean, keys: (self: any) -> esTypes.Iterator<T> }

	The shape the set-algebra methods accept: a `size`, a `has`, and a `keys`
	method. A `Set` satisfies it.
]=]
export type SetLike<T> = {
	read size: number,
	has: (self: any, value: T) -> boolean,
	keys: (self: any) -> esTypes.Iterator<T>,
}

--[=[
	@within Set
	@type SetPrototype = { ... }

	The shared method table, `Set.prototype`. It also holds `constructor` and
	`[Symbol.toStringTag]`.
]=]
export type SetPrototype = {
	add: <T>(self: Set<T>, value: T) -> Set<T>,
	has: <T>(self: Set<T>, value: T) -> boolean,
	delete: <T>(self: Set<T>, value: T) -> boolean,
	clear: <T>(self: Set<T>) -> (),
	forEach: <T>(self: Set<T>, callback: (value: T, value2: T, set: Set<T>) -> ()) -> (),
	values: <T>(self: Set<T>) -> esTypes.Iterator<T>,
	keys: <T>(self: Set<T>) -> esTypes.Iterator<T>,
	entries: <T>(self: Set<T>) -> esTypes.Iterator<{ T }>,
	union: <T, U>(self: Set<T>, other: SetLike<U>) -> Set<T | U>,
	intersection: <T, U>(self: Set<T>, other: SetLike<U>) -> Set<T>,
	difference: <T, U>(self: Set<T>, other: SetLike<U>) -> Set<T>,
	symmetricDifference: <T, U>(self: Set<T>, other: SetLike<U>) -> Set<T | U>,
	isSubsetOf: <T, U>(self: Set<T>, other: SetLike<U>) -> boolean,
	isSupersetOf: <T, U>(self: Set<T>, other: SetLike<U>) -> boolean,
	isDisjointFrom: <T, U>(self: Set<T>, other: SetLike<U>) -> boolean,
	constructor: SetStatic,
}

--[=[
	@within Set
	@type SetStatic = { new: <T>(iterable: unknown?) -> Set<T>, prototype: SetPrototype }

	The `Set` module table.
]=]
export type SetStatic = {
	new: <T>(iterable: unknown?) -> Set<T>,
	prototype: SetPrototype,
}

-- Internal layout. Values live in an array indexed by insertion position, and
-- `_index` maps a normalized value to its position. `_epoch` changes on `clear`,
-- so open iterators know to restart.
type SetState<T> = Set<T> & {
	_values: { any },
	_index: { [any]: number },
	_top: number,
	_size: number,
	_epoch: number,
}

const NIL_KEY = newproxy(false)
const NAN_KEY = newproxy(false)
const TOMBSTONE = newproxy(false)

-- Forward declaration: the set-algebra methods build results with `emptySet`,
-- which is assigned below, once the shared metatable exists.
local emptySet: <T>() -> SetState<T>

--[=[
	@within Set
	@private
	Maps a Luau value to the table slot key used internally. Folds `-0` into `+0`.
]=]
const function normalizeValue(value: unknown): any
	if value == nil then
		return NIL_KEY
	end
	if value ~= value then
		return NAN_KEY
	end
	if value == 0 then
		return 0
	end
	return value
end

--[=[
	@within Set
	@private
	The inverse of `normalizeValue`.
]=]
const function denormalizeValue<T>(value: any): T
	if value == NIL_KEY then
		return nil :: any
	end
	if value == NAN_KEY then
		return (0 / 0) :: any
	end
	return value
end

--[=[
	@within Set
	@private
	Builds an iterator over the live members of `set`. `project` turns a member
	into the yielded item. Members added during iteration are visited. Members
	deleted during iteration are skipped. After a `clear`, iteration restarts.
]=]
const function makeIterator<T, R>(set: SetState<T>, project: (value: T) -> R): esTypes.Iterator<R>
	local position = 0
	local epoch = set._epoch
	const iterator = {} :: any
	iterator.next = function(_self: any): esTypes.IteratorResult<R>
		if set._epoch ~= epoch then
			position = 0
			epoch = set._epoch
		end
		while position < set._top do
			position += 1
			const value = set._values[position]
			if value ~= TOMBSTONE then
				return { value = project(denormalizeValue(value)), done = false }
			end
		end
		return { value = nil, done = true }
	end
	iterator[Symbol.iterator] = function(self: any): any
		return self
	end
	return iterator :: esTypes.Iterator<R>
end

--[=[
	@within Set
	@private
	Throws a `TypeError` unless `other` is set-like: it has a numeric `size`, and
	callable `has` and `keys` methods. Returns its `keys` iterator.
]=]
const function otherKeys<U>(other: unknown, method: string): esTypes.Iterator<U>
	if type(other) ~= "table" or Symbol.isSymbol(other) then
		error(TypeError.new("Set.prototype." .. method .. ": argument must be set-like"), 3)
	end
	const tbl = other :: any
	if type(tbl.size) ~= "number" or type(tbl.has) ~= "function" or type(tbl.keys) ~= "function" then
		error(TypeError.new("Set.prototype." .. method .. ": argument must be set-like"), 3)
	end
	return tbl.keys(tbl)
end

--[=[
	@within Set
	@private
	Calls `callback` for each value that `iterator` yields, until it returns
	`false` or the iterator is done.
]=]
const function eachFrom<U>(iterator: esTypes.Iterator<U>, callback: (value: U) -> boolean?)
	while true do
		const step = iterator.next(iterator)
		if step.done then
			return
		end
		if callback(step.value :: U) == false then
			return
		end
	end
end

--[=[
	@within Set
	@private
	Adds `value` to `set` if it is not already a member.
]=]
const function add<T>(self: SetState<T>, value: T): Set<T>
	const normalized = normalizeValue(value)
	if self._index[normalized] == nil then
		const top = self._top + 1
		self._top = top
		self._values[top] = normalized
		self._index[normalized] = top
		self._size += 1
	end
	return self
end

--[=[
	@within Set
	@param self Set<T>
	@param value T -- the value to check
	@return boolean -- `true` if `value` is a member
]=]
const function has<T>(self: SetState<T>, value: T): boolean
	return self._index[normalizeValue(value)] ~= nil
end

--[=[
	@within Set
	@param self Set<T>
	@param value T -- the value to remove
	@return boolean -- `true` if `value` was a member
]=]
const function delete_<T>(self: SetState<T>, value: T): boolean
	const normalized = normalizeValue(value)
	const position = self._index[normalized]
	if position == nil then
		return false
	end
	self._index[normalized] = nil
	self._values[position] = TOMBSTONE
	self._size -= 1
	return true
end

--[=[
	@within Set
	@param self Set<T>

	Removes every member and releases its storage. Iterators that are still open
	restart, and they visit members added after the clear.
]=]
const function clear<T>(self: SetState<T>)
	self._values = {}
	self._index = {}
	self._top = 0
	self._size = 0
	self._epoch += 1
end

--[=[
	@within Set
	@param self Set<T>
	@param callback (value: T, value2: T, set: Set<T>) -> () -- called for each member in order

	Calls `callback` for each live member, in insertion order. The value is passed
	twice, as in JavaScript's `Set.prototype.forEach`.
]=]
const function forEach<T>(self: SetState<T>, callback: (value: T, value2: T, set: Set<T>) -> ())
	if type(callback) ~= "function" then
		error(TypeError.new("Set.prototype.forEach: callback is not a function"), 2)
	end
	local position = 0
	local epoch = self._epoch
	while true do
		if self._epoch ~= epoch then
			position = 0
			epoch = self._epoch
		end
		if position >= self._top then
			break
		end
		position += 1
		const value = self._values[position]
		if value ~= TOMBSTONE then
			const member = denormalizeValue(value) :: T
			callback(member, member, self)
		end
	end
end

--[=[
	@within Set
	@param self Set<T>
	@return esTypes.Iterator<T> -- yields each member, in insertion order
]=]
const function values<T>(self: SetState<T>): esTypes.Iterator<T>
	return makeIterator(self, function(value: T): T
		return value
	end)
end

--[=[
	@within Set
	@param self Set<T>
	@return esTypes.Iterator<{ T }> -- yields each member as a `{ value, value }` pair
]=]
const function entries<T>(self: SetState<T>): esTypes.Iterator<{ T }>
	return makeIterator(self, function(value: T): { T }
		return { value, value }
	end)
end

--[=[
	@within Set
	@param self Set<T>
	@param other SetLike<U> -- see the note on set-like arguments above
	@return Set<T | U> -- a new set with the members of both

	Members of `self` come first, then members of `other` that are not already
	present.
]=]
const function union<T, U>(self: SetState<T>, other: SetLike<U>): Set<T | U>
	const result = emptySet() :: SetState<T | U>
	for position = 1, self._top do
		const value = self._values[position]
		if value ~= TOMBSTONE then
			add(result, denormalizeValue(value))
		end
	end
	eachFrom(otherKeys(other, "union"), function(value: U): nil
		add(result, value)
        return nil
	end)
	return result
end

--[=[
	@within Set
	@param self Set<T>
	@param other SetLike<U> -- see the note on set-like arguments above
	@return Set<T> -- a new set with the members that are in both. Keeps the order of `self`.
]=]
const function intersection<T, U>(self: SetState<T>, other: SetLike<U>): Set<T>
	const result = emptySet() :: SetState<T>
	otherKeys(other, "intersection")
	const otherSet = other :: any
	for position = 1, self._top do
		const value = self._values[position]
		if value ~= TOMBSTONE then
			const member = denormalizeValue(value) :: T
			if otherSet.has(otherSet, member) then
				add(result, member)
			end
		end
	end
	return result
end

--[=[
	@within Set
	@param self Set<T>
	@param other SetLike<U> -- see the note on set-like arguments above
	@return Set<T> -- a new set with the members of `self` that are not in `other`
]=]
const function difference<T, U>(self: SetState<T>, other: SetLike<U>): Set<T>
	const result = emptySet() :: SetState<T>
	otherKeys(other, "difference")
	const otherSet = other :: any
	for position = 1, self._top do
		const value = self._values[position]
		if value ~= TOMBSTONE then
			const member = denormalizeValue(value) :: T
			if not otherSet.has(otherSet, member) then
				add(result, member)
			end
		end
	end
	return result
end

--[=[
	@within Set
	@param self Set<T>
	@param other SetLike<U> -- see the note on set-like arguments above
	@return Set<T | U> -- a new set with the members that are in exactly one of the two sets
]=]
const function symmetricDifference<T, U>(self: SetState<T>, other: SetLike<U>): Set<T | U>
	const result = emptySet() :: SetState<T | U>
	for position = 1, self._top do
		const value = self._values[position]
		if value ~= TOMBSTONE then
			add(result, denormalizeValue(value))
		end
	end
	eachFrom(otherKeys(other, "symmetricDifference"), function(value: U): nil
		if has(self, value :: any) then
			delete_(result, value :: any)
		else
			add(result, value)
		end
        return nil
	end)
	return result
end

--[=[
	@within Set
	@param self Set<T>
	@param other SetLike<U> -- see the note on set-like arguments above
	@return boolean -- `true` if every member of `self` is in `other`
]=]
const function isSubsetOf<T, U>(self: SetState<T>, other: SetLike<U>): boolean
	otherKeys(other, "isSubsetOf")
	const otherSet = other :: any
	if self._size > otherSet.size then
		return false
	end
	for position = 1, self._top do
		const value = self._values[position]
		if value ~= TOMBSTONE and not otherSet.has(otherSet, denormalizeValue(value)) then
			return false
		end
	end
	return true
end

--[=[
	@within Set
	@param self Set<T>
	@param other SetLike<U> -- see the note on set-like arguments above
	@return boolean -- `true` if every member of `other` is in `self`
]=]
const function isSupersetOf<T, U>(self: SetState<T>, other: SetLike<U>): boolean
	local superset = true
	eachFrom(otherKeys(other, "isSupersetOf"), function(value: U): boolean
		if not has(self, value :: any) then
			superset = false
			return false
		end
		return true
	end)
	return superset
end

--[=[
	@within Set
	@param self Set<T>
	@param other SetLike<U> -- see the note on set-like arguments above
	@return boolean -- `true` if `self` and `other` share no members
]=]
const function isDisjointFrom<T, U>(self: SetState<T>, other: SetLike<U>): boolean
	local disjoint = true
	eachFrom(otherKeys(other, "isDisjointFrom"), function(value: U): boolean
		if has(self, value :: any) then
			disjoint = false
			return false
		end
		return true
	end)
	return disjoint
end

const prototype: SetPrototype = {
	add = add,
	has = has,
	delete = delete_,
	clear = clear,
	forEach = forEach,
	values = values,
	keys = values,
	entries = entries,
	union = union,
	intersection = intersection,
	difference = difference,
	symmetricDifference = symmetricDifference,
	isSubsetOf = isSubsetOf,
	isSupersetOf = isSupersetOf,
	isDisjointFrom = isDisjointFrom,
} :: any
;(prototype :: any)[Symbol.iterator] = values
;(prototype :: any)[Symbol.toStringTag] = "Set"

const metatable = {
	__index = function(self: any, key: any): any
		if key == "size" then
			return self._size
		end
		return (prototype :: any)[key]
	end,
}

--[=[
	@within Set
	@return Set<T> -- a new, empty set
]=]
emptySet = function<T>(): SetState<T>
	return setmetatable({
		_values = {},
		_index = {},
		_top = 0,
		_size = 0,
		_epoch = 0,
	}, metatable) :: any
end

--[=[
	@within Set
	@param iterable unknown? -- an iterable of values, added in order. Nil gives an empty set.
	@return Set<T> -- a new set

	Accepts any iterable: another `Set`, a plain array, a string (its code
	points), or a table with a `[Symbol.iterator]` method.
]=]
const function new_<T>(iterable: unknown?): Set<T>
	const set = emptySet() :: SetState<T>
	iterate(iterable, function(value: T)
		add(set, value)
	end)
	return set
end

const Set = {
	new = new_,
	prototype = prototype,
} :: SetStatic
;(prototype :: any).constructor = Set

table.freeze(prototype)
table.freeze(Set)

return Set
