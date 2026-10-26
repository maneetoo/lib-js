--!strict

--[=[
	@class WeakSet

	A Luau implementation of JavaScript's
	[`WeakSet`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakSet).

	A collection of tables or userdata, held weakly. Holding a value in the set
	does not keep it alive. When nothing else references a member, its entry
	disappears on its own, as in JavaScript.

	:::note
	Implemented as a table with `__mode = "k"` (weak keys). Members are
	membership flags only, so the set has no values.
	:::

	:::note
	`WeakSet` has no `size` and no way to iterate its members. Entries can vanish
	during garbage collection, so a count or a listing would be out of date as
	soon as it was returned. JavaScript omits both for the same reason.
	:::

	:::note
	`set.constructor` is `WeakSet`, and `Object.prototype.toString` reports
	`"[object WeakSet]"` through `Symbol.toStringTag`.
	:::

	:::caution
	`add` throws a `TypeError` for a member that is not a table or userdata, as
	JavaScript does. `has` and `delete` return `false` for any value, and never
	throw.
	:::

	:::note
	The shared method table and the module table are frozen with `table.freeze`.
	Each instance stays mutable.
	:::
]=]

const Symbol = require("./Symbol")
const TypeError = require("./Error").TypeError
const iterate = require("./iterate")

--[=[
	@within WeakSet
	@type WeakSet<T> = { add: ..., has: ..., delete: ... }

	A weak set of values of type `T`. `T` should be a table or userdata.
]=]
export type WeakSet<T> = {
	add: (self: WeakSet<T>, value: T) -> WeakSet<T>,
	has: (self: WeakSet<T>, value: T) -> boolean,
	delete: (self: WeakSet<T>, value: T) -> boolean,
}

--[=[
	@within WeakSet
	@type WeakSetPrototype = { add: ..., has: ..., delete: ..., constructor: WeakSetStatic }

	The shared method table, `WeakSet.prototype`.
]=]
export type WeakSetPrototype = {
	add: <T>(self: WeakSet<T>, value: T) -> WeakSet<T>,
	has: <T>(self: WeakSet<T>, value: T) -> boolean,
	delete: <T>(self: WeakSet<T>, value: T) -> boolean,
	constructor: WeakSetStatic,
}

--[=[
	@within WeakSet
	@type WeakSetStatic = { new: <T>(iterable: unknown?) -> WeakSet<T>, prototype: WeakSetPrototype }

	The `WeakSet` module table.
]=]
export type WeakSetStatic = {
	new: <T>(iterable: unknown?) -> WeakSet<T>,
	prototype: WeakSetPrototype,
}

type WeakSetState<T> = WeakSet<T> & {
	_members: { [any]: boolean },
}

const prototype: WeakSetPrototype = {} :: any

--[=[
	@within WeakSet
	@param self WeakSet<T>
	@param value T -- a table or userdata to add
	@return WeakSet<T> -- `self`, for chaining

	:::caution
	Throws a `TypeError` for a value that is not a table or userdata.
	:::
]=]
prototype.add = function<T>(self: WeakSetState<T>, value: T): WeakSet<T>
	const valueType = type(value)
	if valueType ~= "table" and valueType ~= "userdata" then
		error(TypeError.new("Invalid value used in weak set"), 2)
	end
	self._members[value :: any] = true
	return self
end :: <T>(self: WeakSet<T>, value: T) -> WeakSet<T>

--[=[
	@within WeakSet
	@param self WeakSet<T>
	@param value T -- the value to check
	@return boolean -- `true` if `value` is a member
]=]
prototype.has = function<T>(self: WeakSetState<T>, value: T): boolean
	return self._members[value :: any] == true
end :: <T>(self: WeakSet<T>, value: T) -> boolean

--[=[
	@within WeakSet
	@param self WeakSet<T>
	@param value T -- the value to remove
	@return boolean -- `true` if `value` was a member
]=]
prototype.delete = function<T>(self: WeakSetState<T>, value: T): boolean
	const members = self._members
	if members[value :: any] == nil then
		return false
	end
	members[value :: any] = nil
	return true
end :: <T>(self: WeakSet<T>, value: T) -> boolean
(prototype :: any)[Symbol.toStringTag] = "WeakSet"

const metatable = {
	__index = prototype,
}

--[=[
	@within WeakSet
	@param iterable unknown? -- an iterable of tables or userdata to add. Nil gives an empty set.
	@return WeakSet<T> -- a new, empty weak set

	Accepts any iterable (see `AbstractOperations/Iterators/iterate`). Each item
	is validated as `add` validates it.
]=]
const function new_<T>(iterable: unknown?): WeakSet<T>
	const set: WeakSetState<T> = setmetatable({
		_members = setmetatable({}, { __mode = "k" }),
	}, metatable) :: any
	iterate(iterable, function(value: T)
		prototype.add(set, value)
	end)
	return set
end

const WeakSet = {
	new = new_,
	prototype = prototype,
} :: WeakSetStatic
(prototype :: any).constructor = WeakSet

table.freeze(prototype)
table.freeze(WeakSet)

return WeakSet
