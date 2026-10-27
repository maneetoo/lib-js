--!strict

--[=[
	@class create

	A Luau implementation of JavaScript's [`Object.create()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/create).

	Creates a new table whose prototype is the given value, optionally
	defining keys on it in the same call.
]=]

const esTypes = require("../ES17-Types")
const defineProperties = require("./defineProperties")
const setPrototypeOf = require("./setPrototypeOf")
const shared = require("./__shared")

--[=[
	@within create
	@param prototype any? -- the new table's prototype (table/function, or `nil` for none)
	@param properties { [any]: PropertyDescriptor }? -- descriptors to define on the new table
	@return any -- the new table

	Builds an empty table and links it to `prototype` with this library's
	`setPrototypeOf`, so the prototype is modelled the same way everywhere:
	as the `__index` of the table's metatable. `create(nil)` gives a table
	with no metatable at all, mirroring `Object.create(null)`. If `properties`
	is given, it is applied with `defineProperties`.

	An error is raised when `prototype` is not a table, a function or `nil`.

	:::caution
	JavaScript tells `null` (no prototype) apart from `undefined` (a
	`TypeError`). Luau's single `nil` stands for both, so `create()` and
	`create(nil)` are the same and never raise.
	:::

	:::caution
	`properties` follows the limits of `defineProperties`: only `value` has
	an effect, and `get`/`set` are rejected.
	:::
]=]
const function create(prototype: any?, properties: esTypes.Table<any, shared.PropertyDescriptor>?): any
	const kind = type(prototype)
	if prototype ~= nil and kind ~= "table" and kind ~= "function" then
		error(`create: prototype must be a table, a function or nil, got {kind}`, 2)
	end

	const object = setPrototypeOf({}, prototype)
	if properties ~= nil then
		defineProperties(object, properties)
	end
	return object
end

return create
