--!strict

--[=[
	@class findLastIndex

	A Luau implementation of JavaScript's [`Array.prototype.findLastIndex()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/findLastIndex).
]=]

const ECMAScript = require "../../ECMAScript"
const TypeError = require "../../Error" .TypeError
const esTypes = require "../../ES17-Types"

--[=[
	@within findLastIndex
	@param array Array<T> -- the array to search
	@param predicate (value: T, index: number, array: Array<T>) -> boolean -- test for each element
	@return number -- the 0-based index of the last match, or `-1`

	Like `findIndex`, but searches from the end.
]=]
const function findLastIndex<T>(array: esTypes.Array<T>, predicate: (value: T, index: number, array: esTypes.Array<T>) -> boolean): number
	if not ECMAScript.IsCallable(predicate) then
        error(TypeError.new("Array.prototype.findLastIndex: callback is not a function"))
    end
	for index = #array, 1, -1 do
		if predicate(array[index], index - 1, array) then
			return index - 1
		end
	end
	return -1
end

return findLastIndex
