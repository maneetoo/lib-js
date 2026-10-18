--!strict

--[=[
	@class reverse

	A Luau implementation of JavaScript's [`Array.prototype.reverse()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/reverse).
]=]

const esTypes = require "../../ES17-Types"

--[=[
	@within reverse
	@param array Array<T> -- the array to reverse in place
	@return Array<T> -- `array`, after the reversal

	Reverses the elements in place and returns the same table.
]=]
const function reverse<T>(array: esTypes.Array<T>): esTypes.Array<T>
	local left = 1
	local right = #array
	while left < right do
		array[left], array[right] = array[right], array[left]
		left += 1
		right -= 1
	end
	return array
end

return reverse
