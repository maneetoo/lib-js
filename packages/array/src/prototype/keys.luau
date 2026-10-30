--!strict

--[=[
	@class keys

	A Luau implementation of JavaScript's [`Array.prototype.keys()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/keys).
]=]

const __shared = require("../__shared")
const esTypes = require("../../ES17-Types")

--[=[
	@within keys
	@param array Array<T> -- the array to iterate
	@return ArrayIterator<number> -- yields the 0-based indices

	Returns an iterator over the indices. It reads the length on every step, so it
	sees changes made during iteration.
]=]
const function keys<T>(array: esTypes.Array<T>): __shared.ArrayIterator<number>
	local index = 0
	return __shared.makeIterator(function(): (boolean, number?)
		if index >= #array then
			return true, nil
		end
		index += 1
		return false, index - 1
	end)
end

return keys
