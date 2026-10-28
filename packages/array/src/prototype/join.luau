--!strict

--[=[
	@class join

	A Luau implementation of JavaScript's [`Array.prototype.join()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/join).
]=]

const __shared = require("../__shared")
const esTypes = require("../../ES17-Types")

--[=[
	@within join
	@param array Array<T> -- the array to join
	@param separator string? -- placed between elements. Default `","`.
	@return string -- the joined string

	Converts each element to a string and joins them. `nil` elements (`undefined`)
	become empty strings. Nested arrays are joined recursively. A cycle becomes an
	empty string, as in JS.
]=]
const function join<T>(array: esTypes.Array<T>, separator: string?): string
	return __shared.joinValues(array :: esTypes.Array<unknown>, if separator == nil then "," else separator)
end

return join
