--!strict

--[=[
	@class toString

	A Luau implementation of JavaScript's [`Array.prototype.toString()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/toString).
]=]

const esTypes = require "../../ES17-Types"
const __shared = require "../__shared"

--[=[
	@within toString
	@param array Array<T> -- the array to convert
	@return string -- the elements joined with `","`

	The same as `join()` with no separator, as in JS.
]=]
const function toString<T>(array: esTypes.Array<T>): string
	return __shared.joinValues(array :: esTypes.Array<unknown>, ",")
end

return toString
