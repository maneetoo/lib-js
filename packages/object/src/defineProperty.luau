--!strict

--[=[
	@class defineProperty

	A Luau implementation of JavaScript's [`Object.defineProperty()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty).

	Defines a key on a table from a property descriptor and returns that same
	table.
]=]

const esTypes = require("../ES17-Types")
const shared = require("./__shared")

--[=[
	@within defineProperty
	@param object T -- the table to define the key on
	@param key any -- the key to define
	@param descriptor PropertyDescriptor -- describes the key; only `value` has an effect
	@return T -- the same `object`

	Stores `descriptor.value` under `key` with `rawset`. Like JavaScript's
	[[DefineOwnProperty]], this is a definition, not an assignment: the
	table's `__newindex` is not consulted (unlike `assign`).

	Errors, like JavaScript's `TypeError`, are raised when:
	- `object` is not a table;
	- `descriptor` is not a table, or contains `get`/`set`;
	- `key` is `nil`;
	- `key` is new and `object` is frozen or non-extensible (see
	  `preventExtensions`);
	- `object` is frozen and `key` already exists with a different value
	  (redefining it with the same value is accepted, as in JavaScript).

	:::caution
	`writable`, `enumerable` and `configurable` are accepted and **ignored**.
	Luau tables have no per-key attributes: every key is always writable,
	enumerable and configurable unless the whole table is frozen. In
	particular, JavaScript's defaults (`false` for all three when omitted) do
	not apply; `defineProperty(t, "x", { value = 1 })` leaves `t.x` as
	changeable and as visible to `keys` as a plain `t.x = 1`. Use `freeze` for
	real immutability.
	:::

	:::caution
	Accessor properties (`get`/`set`) are not supported and raise an error.
	Luau has no per-key getters or setters short of replacing the table's
	`__index`, which this library reserves for the prototype chain.
	:::

	:::caution
	A descriptor without a `value` cannot create a key: `nil` is not a storable
	value in Luau, so `defineProperty(t, "x", {})` defines nothing (JavaScript
	would create `x` holding `undefined`). On an existing key it leaves the
	current value as it is.
	:::
]=]
const function defineProperty<T>(object: T & esTypes.Table<any, any>, key: any, descriptor: shared.PropertyDescriptor): T
	if type(object) ~= "table" then
		error(`defineProperty: called on a non-object, got {typeof(object :: any)}`, 2)
	end
	shared.validate("defineProperty", key, descriptor)
	shared.define("defineProperty", object, key, descriptor)
	return object
end

return defineProperty
