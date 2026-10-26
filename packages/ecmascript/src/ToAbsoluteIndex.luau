--!strict

--[=[
	@class ToAbsoluteIndex
	@within AbstractOperations

	ECMA-262 §7.1.25 `ToAbsoluteIndex(value, length)`.
	https://tc39.es/ecma262/#sec-toabsoluteindex

	Converts `value` to an integer, `+Infinity`, or `-Infinity`. A finite
	negative result counts back from `length`. The result is not clamped; see
	`ToClampedIndex` for that.
]=]

const Number = require("../Number")
const ToIntegerOrInfinity = require("./ToIntegerOrInfinity")

--[=[
	@within ToAbsoluteIndex
	@param value any -- the relative index
	@param length number -- a non-negative integer
	@return number -- an integer, `math.huge`, or `-math.huge`
]=]
const function ToAbsoluteIndex(value: any, length: number): number
	const int = ToIntegerOrInfinity(value)
	if int ~= Number.POSITIVE_INFINITY and int ~= Number.NEGATIVE_INFINITY and int < 0 then
		return length + int
	end
	return int
end

return ToAbsoluteIndex
