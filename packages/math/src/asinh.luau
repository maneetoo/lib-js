--!strict

--[=[
	@class asinh

	A Luau implementation of JavaScript's
	[`Math.asinh()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/asinh).

	Luau's `math` library has no `asinh`. This uses the fdlibm formulas, which
	are the ones JavaScript engines use.
]=]

const Number = require "../Number"
const log1p = require "./log1p"
const __staticProps = require "./__staticProps"

const TWO_TO_28: number = 268435456
const TWO_TO_MINUS_28: number = 1 / 268435456

--[=[
	@within asinh
	@param x any -- the value whose inverse hyperbolic sine to return
	@return number -- `asinh(x)`. Keeps the sign of `x`, and keeps `-0`.
]=]
const function asinh(x: any): number
	const value: number = Number(x)
	if value ~= value or value == 0 or value == Number.POSITIVE_INFINITY or value == Number.NEGATIVE_INFINITY then
		return value
	end
	const a: number = math.abs(value)
	local result: number
	if a < TWO_TO_MINUS_28 then
		return value
	elseif a > TWO_TO_28 then
		result = math.log(a) + __staticProps.LN2
	elseif a > 2 then
		result = math.log(2 * a + 1 / (math.sqrt(a * a + 1) + a))
	else
		result = log1p(a + a * a / (1 + math.sqrt(1 + a * a)))
	end
	return if value < 0 then -result else result
end

return asinh
