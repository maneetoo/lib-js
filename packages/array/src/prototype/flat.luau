--!strict

--[=[
	@class flat

	A Luau implementation of JavaScript's [`Array.prototype.flat()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/flat).
]=]

const ECMAScript = require("../../ECMAScript")
const esTypes = require("../../ES17-Types")
const __shared = require("../__shared")

--[=[
	@within flat
	@param array Array<T> -- the array to flatten
	@param depth number? -- how many levels to flatten. Default `1`. `math.huge` flattens fully.
	@return Array<unknown> -- a new, flattened array

	Returns a new array with nested arrays spread up to `depth` levels. Negative
	and `NaN` depths flatten nothing.

	:::note
	The result type is `Array<unknown>`, because Luau cannot express the element
	type of a nested array at a given depth.
	:::
]=]
const function flat<T>(array: esTypes.Array<T>, depth: number?): esTypes.Array<unknown>
	local limit = if depth == nil then 1 else ECMAScript.ToIntegerOrInfinity(depth)
	limit = math.max(limit, 0)
	const result: esTypes.Array<unknown> = {}
	__shared.flattenInto(result, 0, array :: esTypes.Array<unknown>, limit)
	return result
end

return flat
