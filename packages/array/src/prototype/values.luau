--!strict

--[=[
	@class values

	A Luau implementation of JavaScript's [`Array.prototype.values()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/values).
]=]

const esTypes = require("../../ES17-Types")
const __shared = require("../__shared")

--[=[
	@within values
	@param array Array<T> -- the array to iterate
	@return ArrayIterator<T> -- yields each element

	Returns an iterator over the values. It reads the length on every step.
]=]
const function values<T>(array: esTypes.Array<T>): __shared.ArrayIterator<T>
	local index = 0
	return __shared.makeIterator(function(): (boolean, T?)
		if index >= #array then
			return true, nil
		end
		index += 1
		return false, array[index]
	end)
end

return values
