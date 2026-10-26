--!strict

--[=[
	@class every

	A Luau implementation of JavaScript's [`Array.prototype.every()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/every).
]=]

const ECMAScript = require("../../ECMAScript")
const TypeError = require("../../Error").TypeError
const esTypes = require("../../ES17-Types")

--[=[
	@within every
	@param array Array<T> -- the array to test
	@param predicate (value: T, index: number, array: Array<T>) -> boolean -- called for each element
	@return boolean -- `true` if `predicate` returns a truthy value for every element

	Returns `true` if `predicate` is truthy for every element. Stops at the first
	falsy result. An empty array gives `true`.
]=]
const function every<T>(
	array: esTypes.Array<T>,
	predicate: (value: T, index: number, array: esTypes.Array<T>) -> boolean
): boolean
	if not ECMAScript.IsCallable(predicate) then
		error(TypeError.new("Array.prototype.every: callback is not a function"))
	end
	const length = #array
	for index = 1, length do
		if not predicate(array[index], index - 1, array) then
			return false
		end
	end
	return true
end

return every
