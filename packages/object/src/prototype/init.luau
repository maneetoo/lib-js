--!strict

--[=[
	@class ObjectPrototype

	A Luau port of JavaScript's [`Object.prototype`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/prototype)
	instance methods: `hasOwnProperty`, `isPrototypeOf`,
	`propertyIsEnumerable`, `toString`, and `valueOf`.
]=]

const prototype = {
	hasOwnProperty = require("@self/hasOwnProperty"),
	isPrototypeOf = require("@self/isPrototypeOf"),
	propertyIsEnumerable = require("@self/propertyIsEnumerable"),
	toString = require("@self/toString"),
	valueOf = require("@self/valueOf"),
}

table.freeze(prototype)
return prototype
