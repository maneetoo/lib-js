--!strict

--[=[
	@class NumberPrototype

	A Luau port of JavaScript's `Number.prototype` instance methods:
	`toExponential`, `toFixed`, `toPrecision`, `toString`, and
	`valueOf`.

	:::caution
	Luau numbers cannot carry a metatable at all — the public
	`setmetatable`/`getmetatable` pair only operates on tables, and
	Luau deliberately omits `debug.setmetatable` (present in reference
	Lua as the only way around that) as a sandboxing measure. That
	means there is no way to make `(5):toFixed(2)` work the way
	`(5).toFixed(2)` does in JS — these functions must always be called
	directly instead: `Number.prototype.toFixed(5, 2)`.
	:::

	:::note
	This table is frozen with `table.freeze` before being returned, so
	none of its methods can be reassigned and no new ones can be added
	from outside.
	:::
]=]

const prototype = {
	toExponential = require("@self/toExponential"),
	toFixed = require("@self/toFixed"),
	toPrecision = require("@self/toPrecision"),
	toString = require("@self/toString"),
	valueOf = require("@self/valueOf"),
}

table.freeze(prototype)
return prototype
