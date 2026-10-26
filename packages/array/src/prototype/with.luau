--!strict

--[=[
	@class with

	A Luau implementation of JavaScript's [`Array.prototype.with()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/with).
]=]

const ECMAScript = require("../../ECMAScript")
const Number = require("../../Number")
const RangeError = require("../../Error").RangeError
const esTypes = require("../../ES17-Types")
const toSlice = require("./slice")

--[=[
	@within with
	@param array Array<T> -- the array to read from
	@param index number -- position to replace. Negative values count from the end.
	@param value T? -- the new value
	@return Array<T> -- a new array with that one element replaced

	The non-mutating form of `array[index] = value`. Throws a `RangeError` if
	`index` is out of range, as JS does.
]=]
const function withFn<T>(array: esTypes.Array<T>, index: number, value: T?): esTypes.Array<T>
	const length = #array
	const relative = ECMAScript.ToIntegerOrInfinity(index)
	const actual = if relative >= 0 then relative else length + relative
	if actual < 0 or actual >= length then
		error(
			RangeError.new(
				"Invalid index: "
					.. if relative % 1 == 0
							and relative > Number.MIN_SAFE_INTEGER
							and relative < Number.MAX_SAFE_INTEGER
						then string.format("%d", relative)
						else Number.prototype.toString(relative)
			)
		)
	end
	const copy = toSlice(array, nil, nil)
	copy[actual + 1] = value :: T
	return copy
end

return withFn
