--!strict

--[=[
	@class Map

	A Luau implementation of JavaScript's
	[`Map`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map).

	An insertion-ordered collection of key/value pairs. Any Luau value can be a
	key, including `nil`, `NaN`, and tables. Keys are compared with
	`SameValueZero`: `NaN` equals `NaN`, and `+0` equals `-0`.

	```lua
	local Map = require(path.to.Map)

	local m = Map.new({ { "a", 1 }, { "b", 2 } })
	m.set(m, "c", 3)
	print(m.size, m.get(m, "b")) -- 3  2
	```

	```lua
	-- Map.groupBy, a static like JavaScript's
	local byType = Map.groupBy(items, function(item, index)
		return item.type
	end)
	local bucket = byType.get(byType, "fruit")
	```

	:::note
	Methods take the map as their first argument, as in
	`Map.prototype.set(map, key, value)`, or as `map.set(map, key, value)`.
	`size` is a read-only property, provided through `__index`.
	`map.constructor` is `Map`, and `Object.prototype.toString` reports
	`"[object Map]"` through `Symbol.toStringTag`.
	:::

	:::caution
	Deleted entries are kept as tombstones until `clear` is called. A map that
	adds and deletes keys without calling `clear` grows without bound. `clear`
	releases the storage.
	:::

	:::caution
	Iterators (`keys`, `values`, `entries`) are not Luau generic-`for`
	iterators. Step them with `it.next(it)` in a `while` loop, as with `Array`.
	:::

	:::note
	`Map` and its prototype table are frozen with `table.freeze`. Each
	instance stays mutable.
	:::
]=]

const Symbol = require("./Symbol")
const TypeError = require("./Error").TypeError
const esTypes = require("./ES17-Types")
const iterate = require("./iterate")

--[=[
	@within Map
	@type Map<K, V> = { read size: number, set: ..., get: ..., has: ..., delete: ..., clear: ..., forEach: ..., keys: ..., values: ..., entries: ... }

	A map from keys of type `K` to values of type `V`. The fields are its methods, and
	`size` is a read-only count.

	:::note
	`entries` yields `{ K | V }` pairs. Luau has no heterogeneous tuple type for
	table values, so the pair is typed as a union.
	:::
]=]
export type Map<K, V> = {
	read size: number,
	set: (self: Map<K, V>, key: K, value: V) -> Map<K, V>,
	get: (self: Map<K, V>, key: K) -> V?,
	getOrInsert: (self: Map<K, V>, key: K, value: V) -> V,
	has: (self: Map<K, V>, key: K) -> boolean,
	delete: (self: Map<K, V>, key: K) -> boolean,
	clear: (self: Map<K, V>) -> (),
	forEach: (self: Map<K, V>, callback: (value: V, key: K, map: Map<K, V>) -> ()) -> (),
	keys: (self: Map<K, V>) -> esTypes.Iterator<K>,
	values: (self: Map<K, V>) -> esTypes.Iterator<V>,
	entries: (self: Map<K, V>) -> esTypes.Iterator<{ K | V }>,
}

--[=[
	@within Map
	@type MapPrototype = { ... }

	The shared method table, `Map.prototype`. It also holds `constructor` and
	`[Symbol.toStringTag]`.
]=]
export type MapPrototype = {
	set: <K, V>(self: Map<K, V>, key: K, value: V) -> Map<K, V>,
	get: <K, V>(self: Map<K, V>, key: K) -> V?,
	getOrInsert: <K, V>(self: Map<K, V>, key: K, value: V) -> V,
	has: <K, V>(self: Map<K, V>, key: K) -> boolean,
	delete: <K, V>(self: Map<K, V>, key: K) -> boolean,
	clear: <K, V>(self: Map<K, V>) -> (),
	forEach: <K, V>(self: Map<K, V>, callback: (value: V, key: K, map: Map<K, V>) -> ()) -> (),
	keys: <K, V>(self: Map<K, V>) -> esTypes.Iterator<K>,
	values: <K, V>(self: Map<K, V>) -> esTypes.Iterator<V>,
	entries: <K, V>(self: Map<K, V>) -> esTypes.Iterator<{ K | V }>,
	constructor: MapStatic,
}

--[=[
	@within Map
	@type MapStatic = { new: <K, V>(iterable: unknown?) -> Map<K, V>, prototype: MapPrototype }

	The `Map` module table.
]=]
export type MapStatic = {
	new: <K, V>(iterable: unknown?) -> Map<K, V>,
	groupBy: <K, V>(items: unknown, callback: (value: V, index: number) -> K) -> Map<K, { V }>,
	prototype: MapPrototype,
}

-- Internal layout. Keys and values live in arrays indexed by insertion position.
-- `_index` maps a normalized key to its position. `_epoch` changes on `clear`, so
-- open iterators know to restart.
type MapState<K, V> = Map<K, V> & {
	_keys: { any },
	_values: { any },
	_index: { [any]: number },
	_top: number,
	_size: number,
	_epoch: number,
}

-- Sentinels stand in for values that Luau table slots cannot hold: `nil` (as a
-- key or a value), `NaN` (as a key), and a deleted slot.
const NIL_KEY = newproxy(false)
const NAN_KEY = newproxy(false)
const NIL_VALUE = newproxy(false)
const TOMBSTONE = newproxy(false)

--[=[
	@within Map
	@private
	Maps a Luau key to the table slot key used internally. Folds `-0` into `+0`.
]=]
const function normalizeKey(key: unknown): any
	if key == nil then
		return NIL_KEY
	end
	if key ~= key then
		return NAN_KEY
	end
	if key == 0 then
		return 0
	end
	return key
end

--[=[
	@within Map
	@private
	The inverse of `normalizeKey`.
]=]
const function denormalizeKey<K>(key: any): K
	if key == NIL_KEY then
		return nil :: any
	end
	if key == NAN_KEY then
		return (0 / 0) :: any
	end
	return key
end

const function wrapValue(value: unknown): any
	return if value == nil then NIL_VALUE else value
end

const function unwrapValue<V>(value: any): V?
	return if value == NIL_VALUE then nil else value
end

--[=[
	@within Map
	@private
	Builds an iterator over the live entries of `map`. `project` turns a key and
	its value into the yielded item. Entries added during iteration are visited.
	Entries deleted during iteration are skipped. After a `clear`, iteration
	restarts, so entries added since the clear are visited.
]=]
const function makeIterator<K, V, T>(map: MapState<K, V>, project: (key: K, value: V?) -> T): esTypes.Iterator<T>
	local position = 0
	local epoch = map._epoch
	const iterator = {} :: any
	iterator.next = function(_self: any): esTypes.IteratorResult<T>
		if map._epoch ~= epoch then
			position = 0
			epoch = map._epoch
		end
		while position < map._top do
			position += 1
			const key = map._keys[position]
			if key ~= TOMBSTONE then
				return { value = project(denormalizeKey(key) :: K, unwrapValue(map._values[position])), done = false }
			end
		end
		return { value = nil, done = true }
	end
	iterator[Symbol.iterator] = function(self: any): any
		return self
	end
	return iterator :: esTypes.Iterator<T>
end

--[=[
	@within Map
	@private
	Throws a `TypeError` if `callback` is not a function.
]=]
const function requireCallable(callback: unknown, method: string)
	if type(callback) ~= "function" then
		error(TypeError.new("Map.prototype." .. method .. ": callback is not a function"), 3)
	end
end

--[=[
	@within Map
	@param self Map<K, V>
	@param key K -- the key to store
	@param value V -- the value to store
	@return Map<K, V> -- `self`, for chaining

	Sets `value` for `key`. An existing key keeps its position in the order.
]=]
const function set<K, V>(self: MapState<K, V>, key: K, value: V): Map<K, V>
	const normalized = normalizeKey(key)
	const position = self._index[normalized]
	if position ~= nil then
		self._values[position] = wrapValue(value)
	else
		const top = self._top + 1
		self._top = top
		self._keys[top] = normalized
		self._values[top] = wrapValue(value)
		self._index[normalized] = top
		self._size += 1
	end
	return self
end

--[=[
	@within Map
	@param self Map<K, V>
	@param key K -- the key to look up
	@return V? -- the value for `key`, or `nil` if there is none
]=]
const function get<K, V>(self: MapState<K, V>, key: K): V?
	const position = self._index[normalizeKey(key)]
	if position == nil then
		return nil
	end
	return unwrapValue(self._values[position])
end

--[=[
	@within Map
	@param self Map<K, V>
	@param key K -- the key to look up
	@param value V -- the value to insert when `key` has no entry
	@return V -- the existing value for `key`, or the inserted one

	Like the TC39 [`Map.prototype.getOrInsert`](https://tc39.es/proposal-upsert/)
	proposal (now Stage 4): when `key` is present its value is returned
	untouched and `value` is ignored; when absent, `key` is set to `value`
	(at the end of the insertion order) and `value` is returned. Removes the
	`has` → `set`/`get` double lookup.

	:::note
	`nil` is a legal stored value here, unlike with `get`: an entry holding
	`nil` already counts as present, so `getOrInsert(m, k, v)` returns `nil`
	and does not overwrite it.
	:::
]=]
const function getOrInsert<K, V>(self: MapState<K, V>, key: K, value: V): V
	const normalized = normalizeKey(key)
	local position = self._index[normalized]
	if position == nil then
		position = self._top + 1
		self._top = position
		self._keys[position] = normalized
		self._values[position] = wrapValue(value)
		self._index[normalized] = position
		self._size += 1
		return value
	end
	return unwrapValue(self._values[position]) :: V
end

--[=[
	@within Map
	@param self Map<K, V>
	@param key K -- the key to check
	@return boolean -- `true` if `key` has an entry, even one whose value is `nil`
]=]
const function has<K, V>(self: MapState<K, V>, key: K): boolean
	return self._index[normalizeKey(key)] ~= nil
end

--[=[
	@within Map
	@param self Map<K, V>
	@param key K -- the key to remove
	@return boolean -- `true` if an entry was removed
]=]
const function delete_<K, V>(self: MapState<K, V>, key: K): boolean
	const normalized = normalizeKey(key)
	const position = self._index[normalized]
	if position == nil then
		return false
	end
	self._index[normalized] = nil
	self._keys[position] = TOMBSTONE
	self._values[position] = nil
	self._size -= 1
	return true
end

--[=[
	@within Map
	@param self Map<K, V>

	Removes every entry and releases its storage. Iterators that are still open
	restart, and they visit entries added after the clear.
]=]
const function clear<K, V>(self: MapState<K, V>)
	self._keys = {}
	self._values = {}
	self._index = {}
	self._top = 0
	self._size = 0
	self._epoch += 1
end

--[=[
	@within Map
	@param self Map<K, V>
	@param callback (value: V, key: K, map: Map<K, V>) -> () -- called for each entry in order

	Calls `callback` for each live entry, in insertion order. Entries added during
	the loop are visited, and entries deleted during it are skipped.
]=]
const function forEach<K, V>(self: MapState<K, V>, callback: (value: V, key: K, map: Map<K, V>) -> ())
	requireCallable(callback, "forEach")
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
		const key = self._keys[position]
		if key ~= TOMBSTONE then
			callback(unwrapValue(self._values[position]) :: V, denormalizeKey(key) :: K, self)
		end
	end
end

--[=[
	@within Map
	@param self Map<K, V>
	@return esTypes.Iterator<K> -- yields each key, in insertion order
]=]
const function keys<K, V>(self: MapState<K, V>): esTypes.Iterator<K>
	return makeIterator(self, function(key: K, _value: V?): K
		return key
	end)
end

--[=[
	@within Map
	@param self Map<K, V>
	@return esTypes.Iterator<V> -- yields each value, in insertion order
]=]
const function values<K, V>(self: MapState<K, V>): esTypes.Iterator<V>
	return makeIterator(self, function(_key: K, value: V?): V
		return value :: V
	end)
end

--[=[
	@within Map
	@param self Map<K, V>
	@return esTypes.Iterator<{ K | V }> -- yields `{ key, value }` pairs, in insertion order

	:::caution
	An entry whose value is `nil` yields a pair with a `nil` second element.
	:::
]=]
const function entries<K, V>(self: MapState<K, V>): esTypes.Iterator<{ K | V }>
	return makeIterator(self, function(key: K, value: V?): { K | V }
		return { key, value :: V }
	end)
end

const prototype: MapPrototype = {
	set = set,
	get = get,
	getOrInsert = getOrInsert,
	has = has,
	delete = delete_,
	clear = clear,
	forEach = forEach,
	keys = keys,
	values = values,
	entries = entries,
} :: any
(prototype :: any)[Symbol.iterator] = entries;
(prototype :: any)[Symbol.toStringTag] = "Map"

const metatable = {
	__index = function(self: any, key: any): any
		if key == "size" then
			return self._size
		end
		return (prototype :: any)[key]
	end,
}

--[=[
	@within Map
	@param iterable unknown? -- an iterable of `{ key, value }` pairs, added in order. Nil gives an empty map.
	@return Map<K, V> -- a new map

	Accepts any iterable: another `Map`, a plain array of pairs, a string (its
	code points), or a table with a `[Symbol.iterator]` method. Each item must be
	a table with a key and a value. Anything else throws a `TypeError`.
]=]
const function new_<K, V>(iterable: unknown?): Map<K, V>
	const map: MapState<K, V> = setmetatable({
		_keys = {},
		_values = {},
		_index = {},
		_top = 0,
		_size = 0,
		_epoch = 0,
	}, metatable) :: any
	iterate(iterable, function(entry: unknown)
		if type(entry) ~= "table" or Symbol.isSymbol(entry) then
			error(TypeError.new("Iterator value " .. tostring(entry) .. " is not an entry object"), 2)
		end
		set(map, (entry :: any)[1], (entry :: any)[2])
	end)
	return map
end

const Map = {
	new = new_,
	prototype = prototype,
} :: MapStatic
(prototype :: any).constructor = Map

--[=[
	@within Map
	@static
	@param items unknown -- any iterable (array, string, another `Map`, anything with `[Symbol.iterator]`); `nil` gives an empty map
	@param callback (value: V, index: number) -> K -- computes the group key for each item
	@return Map<K, { V }> -- a map from each unique returned key to an array of the items that produced it

	A Luau implementation of JavaScript's
	[`Map.groupBy()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map/groupBy).

	Iterates `items` in order, calling `callback(value, index)` for each
	element, and appends the value to the array stored under the returned
	key, creating that array lazily on first use. The result is a real `Map`
	keyed by the callback's return values, so — unlike `Object.groupBy` —
	keys keep their identity and type: tables are keyed by reference, and a
	mutated key object still retrieves its bucket.

	:::note
	`index` is passed 1-based, following Luau array convention, whereas
	JavaScript's callback receives a 0-based index. Adjust by hand
	(`index - 1`) inside `callback` if 0-based indices are needed for parity
	with existing JS logic being ported.
	:::

	:::note
	Items within each bucket preserve their original relative order from
	`items`, matching JavaScript's guarantee. Elements are shared by
	reference, not copied.
	:::

	:::caution
	Unlike `Object.groupBy`, no key coercion happens and none is needed:
	any Luau value the callback returns is a valid `Map` key, including
	`nil`, `NaN`, and `-0` (normalized to `+0`).
	:::
]=]
function Map.groupBy(items: unknown, callback: any): any
	requireCallable(callback, "groupBy")
	const result = new_(nil) :: MapState<any, any>
	local index = 0
	iterate(items, function(value: any)
		index += 1
		const key = callback(value, index)
		local bucket = get(result, key)
		if bucket == nil then
			-- Lazy bucket creation: keys that never appear in the callback's
			-- output never enter the result map.
			set(result, key, { value })
		else
			bucket[#bucket + 1] = value
		end
	end)
	return result
end

table.freeze(prototype)
table.freeze(Map)

return Map
