--!strict

--[=[
	@class findIndex

	A Luau implementation of JavaScript's [`Array.prototype.findIndex()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/findIndex).
]=]

const ECMAScript = require "../../ECMAScript"
const TypeError = require "../../Error" .TypeError
const esTypes = require "../../ES17-Types"

--[=[
	@within findIndex
	@param array Array<T> -- the array to search
	@param predicate (value: T, index: number, array: Array<T>) -> boolean -- test for each element
	@return number -- the 0-based index of the first match, or `-1`

	Returns the index of the first element for which `predicate` is truthy, or `-1`.
]=]
const function findIndex<T>(array: esTypes.Array<T>, predicate: (value: T, index: number, array: esTypes.Array<T>) -> boolean): number
	if not ECMAScript.IsCallable(predicate) then
        error(TypeError.new("Array.prototype.findIndex: callback is not a function"))
    end
	const length = #array
	for index = 1, length do
		if predicate(array[index], index - 1, array) then
			return index - 1
		end
	end
	return -1
end

return findIndex
