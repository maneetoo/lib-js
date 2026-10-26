--!strict

--[=[
	@class log1p

	A Luau implementation of JavaScript's
	[`Math.log1p()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/log1p).

	Luau's `math` library has no `log1p`. This one uses Kahan's correction, so it
	stays accurate for `x` near `0`, where `log(1 + x)` would lose the digits of `x`.
]=]

const Number = require("../Number")

--[=[
	@within log1p
	@param x any -- the value whose `ln(1 + x)` to return
	@return number -- `ln(1 + x)`. `-Infinity` at `x = -1`, `NaN` for `x < -1`.
]=]
const function log1p(x: any): number
	const value: number = Number(x)
	const u: number = 1 + value
	if u == 1 then
		return value
	end
	if u == Number.POSITIVE_INFINITY then
		return Number.POSITIVE_INFINITY
	end
	return math.log(u) * value / (u - 1)
end

return log1p
