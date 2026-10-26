--!strict

--[=[
	@class SymbolPrototype

	A Luau port of JavaScript's `Symbol.prototype` instance members:
	`toString`, `valueOf`, and `description`.
]=]

const prototype = {
	constructor = {},
	toString = require("@self/toString"),
	valueOf = require("@self/valueOf"),
	description = require("@self/description"),
	toPrimitive = require("@self/toPrimitive"),
}

return prototype
