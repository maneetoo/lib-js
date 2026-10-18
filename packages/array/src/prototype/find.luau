--!strict

--[=[
	@class find

	A Luau implementation of JavaScript's [`Array.prototype.find()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/find).
]=]

const ECMAScript = require "../../ECMAScript"
const TypeError = require "../../Error" .TypeError
const esTypes = require "../../ES17-Types"

--[=[
	@within find
	@param array Array<T> -- the array to search
	@param predicate (value: T, index: number, array: Array<T>) -> boolean -- test for each element
	@return T? -- the first element for which `predicate` is truthy, or `nil`

	Returns the first element for which `predicate` is truthy, searching from the
	start. Returns `nil` if there is none, which is also what `undefined` looks like.
	Use `findIndex` if you need to tell those cases apart.
]=]
const function find<T>(array: esTypes.Array<T>, predicate: (value: T, index: number, array: esTypes.Array<T>) -> boolean): T?
	if not ECMAScript.IsCallable(predicate) then
        error(TypeError.new("Array.prototype.find: callback is not a function"))
    end
	const length = #array
	for index = 1, length do
		const value = array[index]
		if predicate(value, index - 1, array) then
			return value
		end
	end
	return nil
end

return find
