--!strict

--[=[
	@class splice

	A Luau implementation of JavaScript's [`Array.prototype.splice()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/splice).
]=]

const ECMAScript = require "../../ECMAScript"
const esTypes = require "../../ES17-Types"

--[=[
	@within splice
	@param array Array<T> -- the array to modify in place
	@param start number -- where to start. Negative values count from the end.
	@param deleteCount number? -- how many elements to remove. `nil` removes everything from `start` on.
	@param ... T? -- elements to insert at `start`
	@return Array<T> -- the removed elements, in a new array

	Removes `deleteCount` elements from `start`, inserts the extra arguments in their
	place, and returns the removed elements.

	:::caution
	Luau cannot tell an omitted `deleteCount` from an explicit `nil`. In both
	cases this method removes everything from `start` on. JS only does this when
	the argument is omitted. To remove nothing, pass `0`.
	:::
]=]
const function splice<T>(array: esTypes.Array<T>, start: number, deleteCount: number?, ...: T?): esTypes.Array<T>
	const length = #array
	const actualStart = ECMAScript.ToClampedIndexOrDefault(start, length, 0)
	const itemCount = select("#", ...)

	local actualDelete: number
	if deleteCount == nil then
		actualDelete = length - actualStart
	else
		actualDelete = math.min(math.max(ECMAScript.ToIntegerOrInfinity(deleteCount), 0), length - actualStart)
	end

	const removed: esTypes.Array<T> = table.move(array, actualStart + 1, actualStart + actualDelete, 1, {})

	-- Move the tail to its new position, then clear any slots no longer in use.
	const tailStart = actualStart + actualDelete + 1
	const shift = itemCount - actualDelete
	if tailStart <= length and shift ~= 0 then
		table.move(array, tailStart, length, tailStart + shift)
	end
	if shift < 0 then
		for index = length + shift + 1, length do
			array[index] = nil
		end
	end

	if itemCount > 0 then
		const items = { ... }
		for position = 1, itemCount do
			array[actualStart + position] = items[position] :: T
		end
	end

	return removed
end

return splice
