--!strict

--[=[
	@class entries

	A Luau implementation of JavaScript's [`Array.prototype.entries()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/entries).
]=]

const esTypes = require("../../ES17-Types")
const __shared = require("../__shared")

--[=[
	@within entries
	@param array Array<T> -- the array to iterate
	@return ArrayIterator<Array<unknown>> -- yields `{ index, value }` pairs

	Returns an iterator over `[index, value]` pairs, with 0-based indices. The
	pairs are plain tables, not `Array` instances in the `isArray` sense.
]=]
const function entries<T>(array: esTypes.Array<T>): __shared.ArrayIterator<esTypes.Array<unknown>>
	local index = 0
	return __shared.makeIterator(function(): (boolean, esTypes.Array<unknown>?)
		if index >= #array then
			return true, nil
		end
		index += 1
		return false, { index - 1, array[index] }
	end)
end

return entries
