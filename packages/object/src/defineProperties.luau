--!strict

--[=[
	@class defineProperties

	A Luau implementation of JavaScript's [`Object.defineProperties()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperties).

	Defines several keys on a table at once from a table of property
	descriptors and returns that same table.
]=]

const esTypes = require("../ES17-Types")
const shared = require("./__shared")

--[=[
	@within defineProperties
	@param object T -- the table to define the keys on
	@param properties { [any]: PropertyDescriptor } -- maps each key to its descriptor
	@return T -- the same `object`

	Equivalent to calling `defineProperty` for every own key of `properties`.
	As in JavaScript, every descriptor is validated *before* any key is
	defined, so a malformed descriptor can never leave `object` half-updated.
	Errors raised while defining (a frozen or non-extensible `object`) can
	still happen midway, again as in JavaScript.

	Errors are also raised when `object` or `properties` is not a table.

	:::caution
	The same limits as `defineProperty` apply: only `value` has an effect,
	`get`/`set` are rejected, and a descriptor without a `value` defines
	nothing.
	:::

	:::note
	Like every table-walking function in this library, `properties` is read
	with `next`, so the order in which keys are defined follows Luau's
	unspecified iteration order.
	:::
]=]
const function defineProperties<T>(
	object: T & esTypes.Table<any, any>,
	properties: esTypes.Table<any, shared.PropertyDescriptor>
): T
	if type(object) ~= "table" then
		error(`defineProperties: called on a non-object, got {typeof(object :: any)}`, 2)
	end
	if type(properties) ~= "table" then
		error(`defineProperties: properties must be a table, got {typeof(properties :: any)}`, 2)
	end

	for key, descriptor in next, properties do
		shared.validate("defineProperties", key, descriptor)
	end
	for key, descriptor in next, properties do
		shared.define("defineProperties", object, key, descriptor)
	end

	return object
end

return defineProperties
