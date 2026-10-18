--!strict

--[=[
	@class isSafeInteger

	A Luau implementation of JavaScript's
	[`Number.isSafeInteger()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isSafeInteger).

	Checks whether a value is an integer that can be exactly represented
	as an IEEE-754 double — i.e. one where no other integer would round
	to the same floating-point value.
]=]

const isInteger = require "./isInteger"
const __staticProps = require "./__staticProps"

--[=[
	@within isSafeInteger
	@param value any -- the value to test
	@return boolean -- `true` if `value` is an integer within ±`Number.MAX_SAFE_INTEGER`

	Equivalent to `isInteger(value) and math.abs(value) <= Number.MAX_SAFE_INTEGER`.
	Beyond this range, consecutive doubles are spaced more than `1`
	apart, so integers can silently collide (`2^53 == 2^53 + 1` as
	doubles) — this function reports `false` for anything past that
	point, exactly as JS does.
]=]
const function isSafeInteger(value: any): boolean
	return isInteger(value) and math.abs(value :: number) <= __staticProps.MAX_SAFE_INTEGER
end

return isSafeInteger
