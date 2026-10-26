--!strict

--[=[
	@class includes

	A Luau implementation of JavaScript's [`Array.prototype.includes()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/includes).
]=]

const ECMAScript = require("../../ECMAScript")
const esTypes = require("../../ES17-Types")

--[=[
	@within includes
	@param array Array<T> -- the array to search
	@param search T? -- the value to look for
	@param fromIndex number? -- where to start searching. Negative values count from the end.
	@return boolean -- `true` if `search` is in the array

	Uses `SameValueZero`, so `NaN` matches `NaN`. Unlike `indexOf`, it finds `nil`
	(`undefined`) elements.
]=]
const function includes<T>(array: esTypes.Array<T>, search: T?, fromIndex: number?): boolean
	const length = #array
	if length == 0 then
		return false
	end
	const start = ECMAScript.ToClampedIndexOrDefault(fromIndex, length, 0)
	const searchIsTable = type(search) == "table"
	-- NaN is the only value that is not equal to itself. SameValueZero matches it to NaN.
	const searchIsNaN = search ~= search
	for index = start + 1, length do
		const element = array[index]
		if element == search then
			if not searchIsTable or rawequal(element, search) then
				return true
			end
		elseif searchIsNaN and element ~= element then
			return true
		end
	end
	return false
end

return includes
