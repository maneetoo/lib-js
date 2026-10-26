--!strict

--[=[
	@class WeakRef

	A Luau implementation of JavaScript's
	[`WeakRef`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakRef).

	A weak reference to a single table or userdata. The reference does not keep
	its target alive. After the target becomes unreachable and a garbage
	collection cycle runs, `deref` returns `nil`.

	:::note
	Implemented with a table that has `__mode = "v"` (weak values), which holds
	the target. The target stays alive while any strong reference to it exists.
	:::

	:::note
	`ref.constructor` is `WeakRef`, and `Object.prototype.toString` reports
	`"[object WeakRef]"` through `Symbol.toStringTag`.
	:::

	:::caution
	When and whether the target is collected is up to the garbage collector.
	Code must not depend on the timing. A target that is still reachable keeps
	returning from `deref`.
	:::

	:::caution
	`new` throws a `TypeError` for a target that is not a table or userdata, as
	JavaScript does for a non-object target.
	:::

	:::note
	The shared method table and the module table are frozen with `table.freeze`.
	Each instance is immutable from the outside.
	:::
]=]

const Symbol = require("./Symbol")
const TypeError = require("./Error").TypeError

--[=[
	@within WeakRef
	@type WeakRef<T> = { deref: (self: WeakRef<T>) -> T? }

	A weak reference to a value of type `T`.
]=]
export type WeakRef<T> = {
	deref: (self: WeakRef<T>) -> T?,
}

--[=[
	@within WeakRef
	@type WeakRefPrototype = { deref: ..., constructor: WeakRefStatic }

	The shared method table, `WeakRef.prototype`.
]=]
export type WeakRefPrototype = {
	deref: <T>(self: WeakRef<T>) -> T?,
	constructor: WeakRefStatic,
}

--[=[
	@within WeakRef
	@type WeakRefStatic = { new: <T>(target: T) -> WeakRef<T>, prototype: WeakRefPrototype }

	The `WeakRef` module table.
]=]
export type WeakRefStatic = {
	new: <T>(target: T) -> WeakRef<T>,
	prototype: WeakRefPrototype,
}

type WeakRefState<T> = WeakRef<T> & {
	_cell: { T? },
}

const prototype: WeakRefPrototype = {} :: any

--[=[
	@within WeakRef
	@param self WeakRef<T>
	@return T? -- the target, or `nil` once it has been collected
]=]
prototype.deref = function<T>(self: WeakRefState<T>): T?
	return self._cell[1]
end :: <T>(self: WeakRef<T>) -> T?
(prototype :: any)[Symbol.toStringTag] = "WeakRef"

const metatable = {
	__index = prototype,
}

--[=[
	@within WeakRef
	@param target T -- a table or userdata to refer to weakly
	@return WeakRef<T> -- a new weak reference to `target`

	:::caution
	Throws a `TypeError` for a target that is not a table or userdata.
	:::
]=]
const function new_<T>(target: T): WeakRef<T>
	const targetType = type(target)
	if targetType ~= "table" and targetType ~= "userdata" then
		error(TypeError.new("WeakRef: target must be an object"), 2)
	end
	return setmetatable({
		_cell = setmetatable({ target :: any }, { __mode = "v" }),
	}, metatable) :: any
end

const WeakRef = {
	new = new_,
	prototype = prototype,
} :: WeakRefStatic
(prototype :: any).constructor = WeakRef

table.freeze(prototype)
table.freeze(WeakRef)

return WeakRef
