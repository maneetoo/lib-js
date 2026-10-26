--!strict

--[=[
	@class some

	A Luau implementation of JavaScript's [`Array.prototype.some()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/some).
]=]

const ECMAScript = require("../../ECMAScript")
const TypeError = require("../../Error").TypeError
const esTypes = require("../../ES17-Types")

--[=[
	@within some
	@param array Array<T> -- the array to test
	@param predicate (value: T, index: number, array: Array<T>) -> boolean -- test for each element
	@return boolean -- `true` if `predicate` is truthy for any element

	Returns `true` at the first element for which `predicate` is truthy. An empty
	array gives `false`.
]=]
const function some<T>(
	array: esTypes.Array<T>,
	predicate: (value: T, index: number, array: esTypes.Array<T>) -> boolean
): boolean
	if not ECMAScript.IsCallable(predicate) then
		error(TypeError.new("Array.prototype.some: callback is not a function"))
	end
	const length = #array
	for index = 1, length do
		if predicate(array[index], index - 1, array) then
			return true
		end
	end
	return false
end

return some
