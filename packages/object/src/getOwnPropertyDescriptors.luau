--!strict

--[=[
	@class getOwnPropertyDescriptors

	A Luau implementation of JavaScript's [`Object.getOwnPropertyDescriptors()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/getOwnPropertyDescriptors).

	Returns a table mapping every own key of a table to its descriptor.
]=]

const esTypes = require("../ES17-Types")
const shared = require("./__shared")

--[=[
	@within getOwnPropertyDescriptors
	@param object any -- the table to inspect
	@return { [any]: PropertyDescriptor } -- a fresh table holding one descriptor per own key

	Equivalent to calling `getOwnPropertyDescriptor` for every own key, which
	is why the same rules apply: flags describe what is actually true
	(`enumerable` is always `true`, `writable`/`configurable` are `false`
	only on a frozen table), and keys keep their original Luau type.

	Because `defineProperties` accepts exactly this shape, a table can be
	shallow-copied together with its keys' definitions:
	`defineProperties(create(getPrototypeOf(source)), getOwnPropertyDescriptors(source))`.

	Non-table values have no own keys and yield an empty table. A `nil`
	`object` raises an error, as JavaScript does for `null`/`undefined`.

	:::note
	Like `keys`, the keys are read with `next`, so symbol keys (see
	`getOwnPropertySymbols`) are included.
	:::
]=]
const function getOwnPropertyDescriptors(object: any): esTypes.Table<any, shared.PropertyDescriptor>
	if object == nil then
		error("getOwnPropertyDescriptors: cannot convert undefined or null to object", 2)
	end

	const descriptors: esTypes.Table<any, shared.PropertyDescriptor> = {}
	if type(object) ~= "table" then
		return descriptors
	end

	-- One frozen check for the whole table instead of one per key.
	const mutable = not table.isfrozen(object)
	for key, value in next, object :: any do
		descriptors[key] = shared.describe(value, mutable)
	end
	return descriptors
end

return getOwnPropertyDescriptors
