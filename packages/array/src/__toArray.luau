--!strict

--[=[
	@class __toArray
    @private

	A Luau implementation of JavaScript's [`new Array()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/Array).
]=]

const RangeError = require "../Error" .RangeError
const esTypes = require "../ES17-Types"
const of = require "./of"

--[=[
	@within __toArray
	@param ... unknown -- either one non-negative integer length, or the elements
	@return Array<T> -- the new array

	`new Array(...)`. With one number argument, JS creates an array of that length
	with holes. Luau cannot store that, so this returns an empty table (length `0`).
	With any other arguments, it creates an array of those elements.

	:::caution
	`new Array(3)` has length `0` here, not `3`. Code that relies on the length,
	like `new Array(3).fill(0)`, gets an empty array. Build the array with
	`Array.of` or a loop instead.
	:::

	:::caution
	A `RangeError` is thrown for a negative, fractional, or too large length, as in JS.
	:::
]=]
const function toArray<T>(...: T?): esTypes.Array<T>
	const count = select("#", ...)
	if count == 1 and type((...)) == "number" then
		const length = (...) :: number
		if length ~= length or length < 0 or length % 1 ~= 0 or length > 4294967295 then
			error(RangeError.new("Invalid array length"))
		end
		return {}
	end
	return of(...)
end

return toArray
