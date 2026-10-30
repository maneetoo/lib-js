--!strict

--[=[
	@class slice

	A Luau implementation of JavaScript's [`Array.prototype.slice()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/slice).
]=]

const ECMAScript = require("../../ECMAScript")
const esTypes = require("../../ES17-Types")

--[=[
	@within slice
	@param array Array<T> -- the array to read from
	@param start number? -- first position (inclusive). Default `0`.
	@param finish number? -- end position (exclusive). Default: the length.
	@return Array<T> -- a new array with the selected elements

	Returns a new array with a shallow copy of the selected range. Negative
	positions count from the end. `array` is not changed.
]=]
const function slice<T>(array: esTypes.Array<T>, start: number?, finish: number?): esTypes.Array<T>
	const length = #array
	const from = ECMAScript.ToClampedIndexOrDefault(start, length, 0)
	const to = ECMAScript.ToClampedIndexOrDefault(finish, length, length)
	const result: esTypes.Array<T> = {}
	if to > from then
		table.move(array, from + 1, to, 1, result)
	end
	return result
end

return slice
