--!strict

--[=[
	@class toSpliced

	A Luau implementation of JavaScript's [`Array.prototype.toSpliced()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/toSpliced).
]=]

const esTypes = require("../../ES17-Types")
const splice = require("./splice")
const toSlice = require("./slice")

--[=[
	@within toSpliced
	@param array Array<T> -- the array to read from
	@param start number -- where to start
	@param deleteCount number? -- how many elements to remove. `nil` removes everything from `start` on.
	@param ... T? -- elements to insert
	@return Array<T> -- a new array with the change applied

	The non-mutating form of `splice`. `array` is not changed, and the removed
	elements are not returned. The same `deleteCount` caveat applies.
]=]
const function toSpliced<T>(array: esTypes.Array<T>, start: number, deleteCount: number?, ...: T?): esTypes.Array<T>
	const copy = toSlice(array, nil, nil)
	splice(copy, start, deleteCount, ...)
	return copy
end

return toSpliced
