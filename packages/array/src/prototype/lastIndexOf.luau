--!strict

--[=[
	@class lastIndexOf

	A Luau implementation of JavaScript's [`Array.prototype.lastIndexOf()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/lastIndexOf).
]=]

const ECMAScript = require("../../ECMAScript")
const esTypes = require("../../ES17-Types")

--[=[
	@within lastIndexOf
	@param array Array<T> -- the array to search
	@param search T? -- the value to look for
	@param fromIndex number? -- where to start searching backward. Negative values count from the end.
	@return number -- the 0-based index of the last match, or `-1`

	Searches from `fromIndex` (or the end) toward the start, with strict equality.
]=]
const function lastIndexOf<T>(array: esTypes.Array<T>, search: T?, fromIndex: number?): number
	const length = #array
	if length == 0 then
		return -1
	end

	local start: number
	if fromIndex == nil then
		start = length - 1
	else
		const relative = ECMAScript.ToIntegerOrInfinity(fromIndex)
		if relative == -math.huge then
			return -1
		end
		start = if relative >= 0 then math.min(relative, length - 1) else length + relative
	end

	const searchIsTable = type(search) == "table"
	for index = start, 0, -1 do
		const element = array[index + 1]
		if element == search and (not searchIsTable or rawequal(element, search)) then
			return index
		end
	end
	return -1
end

return lastIndexOf
