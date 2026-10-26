--!strict

--[=[
	@class push

	A Luau implementation of JavaScript's [`Array.prototype.push()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/push).
]=]

const esTypes = require("../../ES17-Types")

--[=[
	@within push
	@param array Array<T> -- the array to modify in place
	@param ... T? -- values to append
	@return number -- the new length

	Appends the arguments to the end, in place, and returns the new length.

	:::caution
	Pushing `nil` (`undefined`) does not extend the array, because `#` cannot
	count a trailing `nil`. The returned length still counts it.
	:::
]=]
const function push<T>(array: esTypes.Array<T>, ...: T?): number
	local length = #array
	const count = select("#", ...)
	if count == 1 then
		length += 1
		array[length] = (...) :: T
		return length
	end

	const items = { ... }
	for position = 1, count do
		length += 1
		array[length] = items[position] :: T
	end
	return length
end

return push
