--!strict

--[=[
	@class filter

	A Luau implementation of JavaScript's [`Array.prototype.filter()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/filter).
]=]

const ECMAScript = require("../../ECMAScript")
const TypeError = require("../../Error").TypeError
const esTypes = require("../../ES17-Types")

--[=[
	@within filter
	@param array Array<T> -- the array to read from
	@param predicate (value: T, index: number, array: Array<T>) -> boolean -- keeps the element when truthy
	@return Array<T> -- a new array with the kept elements, in order

	Returns a new array with the elements for which `predicate` is truthy. The
	original array is not changed.
]=]
const function filter<T>(
	array: esTypes.Array<T>,
	predicate: (value: T, index: number, array: esTypes.Array<T>) -> boolean
): esTypes.Array<T>
	if not ECMAScript.IsCallable(predicate) then
		error(TypeError.new("Array.prototype.filter: callback is not a function"))
	end
	const result: esTypes.Array<T> = {}
	local count = 0
	const length = #array
	for index = 1, length do
		const value = array[index]
		if predicate(value, index - 1, array) then
			count += 1
			result[count] = value
		end
	end
	return result
end

return filter
