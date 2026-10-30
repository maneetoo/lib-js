--!strict

--[=[
	@class Object

	A Luau port of JavaScript's [`Object`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object):
	the static helpers (`assign`, `create`, `defineProperties`,
	`defineProperty`, `entries`, `freeze`, `fromEntries`,
	`getOwnPropertyDescriptor`, `getOwnPropertyDescriptors`,
	`getOwnPropertyNames`, `getOwnPropertySymbols`, `getPrototypeOf`,
	`groupBy`, `hasOwn`, `is`, `isExtensible`, `isFrozen`, `isSealed`,
	`keys`, `preventExtensions`, `seal`, `setPrototypeOf`, `values`) and an
	`Object.prototype` sub-table holding `hasOwnProperty`, `isPrototypeOf`,
	`propertyIsEnumerable`, `toString`, and `valueOf`.

	:::note
	`Object` is not callable: there is no `Object(value)` constructor
	form. Primitive values are never wrapped in an object; the
	prototype methods are called directly with the value as their first
	argument, e.g. `Object.prototype.toString(value)`.
	:::

	:::caution
	Luau tables have no per-key attributes (`writable`, `enumerable`,
	`configurable`) and no accessor properties, so the property-descriptor
	methods (`defineProperty`, `defineProperties`, `create`'s second
	argument, `getOwnPropertyDescriptor(s)`) work with plain *data*
	descriptors only; see `PropertyDescriptor`.
	:::

	:::caution
	`seal` cannot stop keys from being *removed* (only added), and
	`isSealed` only recognises tables sealed through this library; see
	`seal` and `isSealed`.
	:::
]=]

const prototype = require("@self/prototype")
const shared = require("@self/__shared")

export type PropertyDescriptor = shared.PropertyDescriptor

const Object = {
	assign = require("@self/assign"),
	create = require("@self/create"),
	defineProperties = require("@self/defineProperties"),
	defineProperty = require("@self/defineProperty"),
	entries = require("@self/entries"),
	freeze = require("@self/freeze"),
	fromEntries = require("@self/fromEntries"),
	getOwnPropertyDescriptor = require("@self/getOwnPropertyDescriptor"),
	getOwnPropertyDescriptors = require("@self/getOwnPropertyDescriptors"),
	getOwnPropertyNames = require("@self/getOwnPropertyNames"),
	getOwnPropertySymbols = require("@self/getOwnPropertySymbols"),
	getPrototypeOf = require("@self/getPrototypeOf"),
	groupBy = require("@self/groupBy"),
	hasOwn = require("@self/hasOwn"),
	is = require("@self/is"),
	isExtensible = require("@self/isExtensible"),
	isFrozen = require("@self/isFrozen"),
	isSealed = require("@self/isSealed"),
	keys = require("@self/keys"),
	preventExtensions = require("@self/preventExtensions"),
	seal = require("@self/seal"),
	setPrototypeOf = require("@self/setPrototypeOf"),
	values = require("@self/values"),

	prototype = prototype,
}

table.freeze(Object)

return Object
