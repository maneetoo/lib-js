--!strict

--[=[
	@class concat

	A Luau implementation of JavaScript's [`Array.prototype.concat()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/concat).
]=]

const esTypes = require("../../ES17-Types")
const isArray = require("../isArray")

--[=[
	@within concat
	@param array Array<T> -- the first array
	@param ... (T | Array<T>) -- values or arrays to append
	@return Array<T> -- a new array with `array`'s elements, then each argument's

	Returns a new array. Array arguments are spread one level. Other values are
	appended as-is. `array` itself is not changed.

	:::caution
	Arguments are typed with one element type `T`, so mixed element types need an
	explicit cast on the caller side. JS allows them without one.
	:::

	:::note
	A table with only positive integer keys counts as an array, so `{}` is
	spread as an empty array. This follows the `isArray` rule in `Array`.
	:::
]=]
const function concat<T>(array: esTypes.Array<T>, ...: T | esTypes.Array<T>): esTypes.Array<T>
	const length = #array
	const result: esTypes.Array<T> = table.move(array, 1, length, 1, {})

	-- Packing once is linear. Calling select(position, ...) in a loop is quadratic.
	const count = select("#", ...)
	const items = { ... }
	local total = length
	for position = 1, count do
		const item = items[position]
		if isArray(item) then
			const source = item :: esTypes.Array<T>
			const sourceLength = #source
			table.move(source, 1, sourceLength, total + 1, result)
			total += sourceLength
		else
			total += 1
			result[total] = item :: T
		end
	end

	return result
end

return concat
