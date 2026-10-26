--!strict

--[=[
	@class toSorted

	A Luau implementation of JavaScript's [`Array.prototype.toSorted()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/toSorted).
]=]

const esTypes = require("../../ES17-Types")
const toSlice = require("./slice")
const sort = require("./sort")

--[=[
	@within toSorted
	@param array Array<T> -- the array to read from
	@param compareFn ((a: T, b: T) -> number)? -- the comparison, as for `sort`
	@return Array<T> -- a new, sorted array

	The non-mutating form of `sort`. `array` is not changed.
]=]
const function toSorted<T>(array: esTypes.Array<T>, compareFn: ((a: T, b: T) -> number)?): esTypes.Array<T>
	return sort(toSlice(array, nil, nil), compareFn)
end

return toSorted
