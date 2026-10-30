--!strict

--[=[
	@class map

	A Luau implementation of JavaScript's [`Array.prototype.map()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/map).
]=]

const ECMAScript = require("../../ECMAScript")
const TypeError = require("../../Error").TypeError
const esTypes = require("../../ES17-Types")

--[=[
	@within map
	@param array Array<T> -- the array to read from
	@param callback (value: T, index: number, array: Array<T>) -> U -- the mapping function
	@return Array<U> -- a new array with the mapped values

	Returns a new array of the same length, with each element replaced by
	`callback`'s result. A `nil` result is stored as `undefined`.
]=]
const function map<T, U>(
	array: esTypes.Array<T>,
	callback: (value: T, index: number, array: esTypes.Array<T>) -> U
): esTypes.Array<U>
	if not ECMAScript.IsCallable(callback) then
		error(TypeError.new("Array.prototype.map: callback is not a function"))
	end
	const result: esTypes.Array<U> = {}
	const length = #array
	for index = 1, length do
		result[index] = callback(array[index], index - 1, array)
	end
	return result
end

return map
