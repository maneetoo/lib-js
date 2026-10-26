--!strict

--[=[
	@class unshift

	A Luau implementation of JavaScript's [`Array.prototype.unshift()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/unshift).
]=]

const esTypes = require("../../ES17-Types")

--[=[
	@within unshift
	@param array Array<T> -- the array to modify in place
	@param ... T? -- values to insert at the start
	@return number -- the new length

	Inserts the arguments at the start, in place, and returns the new length. The
	same `nil` caveat as `push` applies.
]=]
const function unshift<T>(array: esTypes.Array<T>, ...: T?): number
	const length = #array
	const count = select("#", ...)
	if count == 0 then
		return length
	end
	if count == 1 then
		table.move(array, 1, length, 2)
		array[1] = (...) :: T
		return length + 1
	end

	const items = { ... }
	table.move(array, 1, length, count + 1)
	for position = 1, count do
		array[position] = items[position] :: T
	end
	return length + count
end

return unshift
