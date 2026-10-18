--!strict

--[=[
	@class forEach

	A Luau implementation of JavaScript's [`Array.prototype.forEach()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/forEach).
]=]

const ECMAScript = require "../../ECMAScript"
const TypeError = require "../../Error" .TypeError
const esTypes = require "../../ES17-Types"

--[=[
	@within forEach
	@param array Array<T> -- the array to walk
	@param callback (value: T, index: number, array: Array<T>) -> () -- called for each element

	Calls `callback` for each element, in order. Returns nothing.
]=]
const function forEach<T>(array: esTypes.Array<T>, callback: (value: T, index: number, array: esTypes.Array<T>) -> ())
	if not ECMAScript.IsCallable(callback) then
        error(TypeError.new("Array.prototype.forEach: callback is not a function"))
    end
	const length = #array
	for index = 1, length do
		callback(array[index], index - 1, array)
	end
end

return forEach
