--!strict

--[=[
	@class acosh

	A Luau implementation of JavaScript's
	[`Math.acosh()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/acosh).

	Luau's `math` library has no `acosh`. This uses the fdlibm formulas, which
	are the ones JavaScript engines use.
]=]

const Number = require("../Number")
const log1p = require("./log1p")
const __staticProps = require("./__staticProps")

const TWO_TO_28: number = 268435456

--[=[
	@within acosh
	@param x any -- the value whose inverse hyperbolic cosine to return
	@return number -- `acosh(x)`, or `NaN` if `x < 1`
]=]
const function acosh(x: any): number
	const value: number = Number(x)
	if not (value >= 1) then
		return Number.NaN
	end
	if value == Number.POSITIVE_INFINITY then
		return Number.POSITIVE_INFINITY
	end
	if value > TWO_TO_28 then
		return math.log(value) + __staticProps.LN2
	end
	if value == 1 then
		return 0
	end
	if value > 2 then
		return math.log(2 * value - 1 / (value + math.sqrt(value * value - 1)))
	end
	const t: number = value - 1
	return log1p(t + math.sqrt(2 * t + t * t))
end

return acosh
