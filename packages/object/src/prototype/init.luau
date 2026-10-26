--!strict

--[=[
	@class ObjectPrototype

	A Luau port of JavaScript's [`Object.prototype`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/prototype)
	instance methods: `hasOwnProperty`, `isPrototypeOf`, and `toString`.
]=]

const prototype = {
	hasOwnProperty = require("@self/hasOwnProperty"),
	isPrototypeOf = require("@self/isPrototypeOf"),
	toString = require("@self/toString"),
}

table.freeze(prototype)
return prototype
