--!strict

--[=[
	@class shift

	A Luau implementation of JavaScript's [`Array.prototype.shift()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/shift).
]=]

const esTypes = require "../../ES17-Types"

--[=[
	@within shift
	@param array Array<T> -- the array to modify in place
	@return T? -- the removed first element, or `nil` if the array is empty

	Removes the first element and returns it, in place. The rest move down one place.
]=]
const function shift<T>(array: esTypes.Array<T>): T?
	const length = #array
	if length == 0 then
		return nil
	end
	const first = array[1]
	table.move(array, 2, length, 1)
	array[length] = nil
	return first
end

return shift
