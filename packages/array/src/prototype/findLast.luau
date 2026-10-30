--!strict

--[=[
	@class findLast

	A Luau implementation of JavaScript's [`Array.prototype.findLast()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/findLast).
]=]

const ECMAScript = require("../../ECMAScript")
const TypeError = require("../../Error").TypeError
const esTypes = require("../../ES17-Types")

--[=[
	@within findLast
	@param array Array<T> -- the array to search
	@param predicate (value: T, index: number, array: Array<T>) -> boolean -- test for each element
	@return T? -- the last element for which `predicate` is truthy, or `nil`

	Like `find`, but searches from the end.
]=]
const function findLast<T>(
	array: esTypes.Array<T>,
	predicate: (value: T, index: number, array: esTypes.Array<T>) -> boolean
): T?
	if not ECMAScript.IsCallable(predicate) then
		error(TypeError.new("Array.prototype.findLast: callback is not a function"))
	end
	for index = #array, 1, -1 do
		const value = array[index]
		if predicate(value, index - 1, array) then
			return value
		end
	end
	return nil
end

return findLast
