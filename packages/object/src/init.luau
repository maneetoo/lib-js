--!strict

--[=[
	@class Object

	A Luau port of JavaScript's [`Object`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object):
	the static helpers (`assign`, `entries`, `freeze`, `fromEntries`,
	`getOwnPropertyNames`, `getPrototypeOf`, `groupBy`, `hasOwn`, `is`,
	`isFrozen`, `keys`, `setPrototypeOf`, `values`) and an
	`Object.prototype` sub-table holding `hasOwnProperty`,
	`isPrototypeOf`, and `toString`.

	:::note
	`Object` is not callable: there is no `Object(value)` constructor
	form. Primitive values are never wrapped in an object; the
	prototype methods are called directly with the value as their first
	argument, e.g. `Object.prototype.toString(value)`.
	:::
]=]

const prototype = require("@self/prototype")

const Object = {
	assign = require("@self/assign"),
	entries = require("@self/entries"),
	freeze = require("@self/freeze"),
	fromEntries = require("@self/fromEntries"),
	getOwnPropertyNames = require("@self/getOwnPropertyNames"),
	getPrototypeOf = require("@self/getPrototypeOf"),
	groupBy = require("@self/groupBy"),
	hasOwn = require("@self/hasOwn"),
	is = require("@self/is"),
	isFrozen = require("@self/isFrozen"),
	keys = require("@self/keys"),
	setPrototypeOf = require("@self/setPrototypeOf"),
	values = require("@self/values"),

	prototype = prototype,
}

table.freeze(Object)

return Object
