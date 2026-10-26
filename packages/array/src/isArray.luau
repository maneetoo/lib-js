--!strict

--[=[
	@class isArray

	A Luau implementation of JavaScript's [`Array.isArray()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/isArray).
]=]

const Symbol = require("../Symbol")
const esTypes = require("../ES17-Types")

--[=[
	@within isArray
	@param value unknown -- the value to test
	@return boolean -- `true` if `value` is an array

	`Array.isArray(value)`.

	:::caution
	Arrays and objects are both plain tables, so this is a heuristic: a table
	counts as an array when every key is a positive integer. `{}` counts as an
	array, and so do `{ [1] = "a", [3] = "c" }` and tables with holes. A table
	with a string key does not count.
	:::
]=]
const function isArray(value: unknown): boolean
	if type(value) ~= "table" or Symbol.isSymbol(value) then
		return false
	end
	for key in pairs(value :: esTypes.Table<unknown, unknown>) do
		if type(key) ~= "number" then
			return false
		end
		if key < 1 or key % 1 ~= 0 then
			return false
		end
	end
	return true
end

return isArray
