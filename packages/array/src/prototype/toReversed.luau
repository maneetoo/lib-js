--!strict

--[=[
	@class toReversed

	A Luau implementation of JavaScript's [`Array.prototype.toReversed()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/toReversed).
]=]

const esTypes = require "../../ES17-Types"
const toSlice = require "./slice"
const reverse = require "./reverse"

--[=[
	@within toReversed
	@param array Array<T> -- the array to read from
	@return Array<T> -- a new, reversed array

	The non-mutating form of `reverse`. `array` is not changed.
]=]
const function toReversed<T>(array: esTypes.Array<T>): esTypes.Array<T>
	return reverse(toSlice(array, nil, nil))
end

return toReversed
