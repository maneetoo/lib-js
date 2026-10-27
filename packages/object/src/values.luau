--!strict

--[=[
	@class values

	A Luau implementation of JavaScript's [`Object.values()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/values).

	Returns an array of a table's own values.
]=]

const esTypes = require("../ES17-Types")
const Symbol = require("../Symbol")

--[=[
	@within values
	@param object { [K]: V } -- the table to list values of
	@return { V } -- an array containing every value found in `object`

	Iterates with `next` directly, so a custom `__iter` metamethod is
	ignored. Values whose keys are symbols are skipped, as in JavaScript.

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
	for key, value in next, object do
		if not Symbol.isSymbol(key) then
			count += 1
			result[count] = value
		end
	end
	return result
end

return values
