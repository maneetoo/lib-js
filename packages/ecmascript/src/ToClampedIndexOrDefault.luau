--!strict

--[=[
	@class ToClampedIndexOrDefault
	@private

	:::caution
	This is not an ECMAScript abstract operation. It is a library helper, and it
	is shared by `String` and `Array`. It wraps `ToClampedIndex`, which is the
	ECMAScript operation, and adds a default for a missing argument.
	:::

	Many `String.prototype` and `Array.prototype` methods take an optional
	relative index, such as `slice(start, end)`. In JavaScript, a missing value
	(`undefined`) is replaced with a default by the method itself. This helper
	does that replacement in one place, and then calls `ToClampedIndex`.
]=]

const ToClampedIndex = require "./ToClampedIndex"

--[=[
	@within ToClampedIndexOrDefault
	@param value any -- the relative index, or `nil` for the default
	@param length number -- the length the index is relative to
	@param default number -- the result when `value` is `nil`
	@return number -- an integer in `0 .. length`

	`ToClampedIndexOrDefault(nil, 5, 0)` gives `0`.
	`ToClampedIndexOrDefault(-2, 5, 0)` gives `3`.
]=]
const function ToClampedIndexOrDefault(value: any, length: number, default: number): number
	if value == nil then
		return default
	end
	return ToClampedIndex(value, length)
end

return ToClampedIndexOrDefault
