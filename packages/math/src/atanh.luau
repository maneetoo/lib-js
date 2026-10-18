--!strict

--[=[
	@class atanh

	A Luau implementation of JavaScript's
	[`Math.atanh()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/atanh).

	Luau's `math` library has no `atanh`. This uses the fdlibm formulas, which
	are the ones JavaScript engines use.
]=]

const Number = require "../Number"
const log1p = require "./log1p"

--[=[
	@within atanh
	@param x any -- the value whose inverse hyperbolic tangent to return, in `[-1, 1]`
	@return number -- `atanh(x)`. `±Infinity` at `±1`, `NaN` for `|x| > 1`.
]=]
const function atanh(x: any): number
	const value: number = Number(x)
	if value ~= value or value > 1 or value < -1 then
		return Number.NaN
	end
	if value == 0 then
		return value
	end
	if value == 1 then
		return Number.POSITIVE_INFINITY
	end
	if value == -1 then
		return Number.NEGATIVE_INFINITY
	end
	const a: number = math.abs(value)
	local result: number
	if a < 0.5 then
		const t = a + a
		result = 0.5 * log1p(t + t * a / (1 - a))
	else
		result = 0.5 * log1p((a + a) / (1 - a))
	end
	return if value < 0 then -result else result
end

return atanh
