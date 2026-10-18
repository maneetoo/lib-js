--!strict

--[=[
	@class BooleanPrototype

	A Luau port of JavaScript's `Boolean.prototype` instance methods:
	`toString` and `valueOf`.

	:::caution
	Luau booleans cannot carry a metatable at all — the public
	`setmetatable`/`getmetatable` pair only operates on tables, and
	Luau deliberately omits `debug.setmetatable` (present in reference
	Lua as the only way around that) as a sandboxing measure. That
	means there is no way to make `(true):toString()` work the way
	`(true).toString()` does in JS — these functions must be called
	directly instead: `Boolean.prototype.toString(true)`.
	:::

	:::note
	This table is frozen with `table.freeze` before being returned, so
	none of its methods can be reassigned and no new ones can be added
	from outside.
	:::
]=]

const prototype = {
	toString = require "@self/toString",
	valueOf = require "@self/valueOf",
}

table.freeze(prototype)
return prototype
