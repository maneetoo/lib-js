--!strict

--[=[
	@class indexOf

	A Luau implementation of JavaScript's [`Array.prototype.indexOf()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/indexOf).
]=]

const ECMAScript = require("../../ECMAScript")
const esTypes = require("../../ES17-Types")

--[=[
	@within indexOf
	@param array Array<T> -- the array to search
	@param search T? -- the value to look for
	@param fromIndex number? -- where to start searching. Negative values count from the end.
	@return number -- the 0-based index of the first match, or `-1`

	Uses strict equality (`===`). `NaN` never matches.
]=]
const function indexOf<T>(array: esTypes.Array<T>, search: T?, fromIndex: number?): number
	const length = #array
	if length == 0 then
		return -1
	end
	const start = ECMAScript.ToClampedIndexOrDefault(fromIndex, length, 0)
	const searchIsTable = type(search) == "table"
	for index = start + 1, length do
		const element = array[index]
		-- `==` on tables may call __eq, so tables also need the rawequal check.
		if element == search and (not searchIsTable or rawequal(element, search)) then
			return index - 1
		end
	end
	return -1
end

return indexOf
