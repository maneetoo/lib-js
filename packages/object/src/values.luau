--!strict

--[=[
	@class values

	A Luau implementation of JavaScript's [`Object.values()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/values).

	Returns an array of a table's own values.
]=]

const esTypes = require("../ES17-Types")

--[=[
	@within values
	@param object { [K]: V } -- the table to list values of
	@return { V } -- an array containing every value found in `object`

	Iterates with `next` directly, so a custom `__iter` metamethod is
	ignored and only genuine own values are reported.

	:::note
	As with `keys`, the order of the returned values follows Luau's
	unspecified iteration order and should not be relied upon. If
	`object`'s values need to line up positionally with `keys(object)`,
	prefer `entries(object)` instead — the language does not guarantee
	that two separate traversals visit keys in the same order.
	:::
]=]
const function values<K, V>(object: esTypes.Table<K, V>): esTypes.Array<V>
	const result: esTypes.Array<V> = {}
	local count = 0
	for _, value in next, object do
		count += 1
		result[count] = value
	end
	return result
end

return values
