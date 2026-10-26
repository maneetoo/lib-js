--!strict

--[=[
	@class expm1

	A Luau implementation of JavaScript's
	[`Math.expm1()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/expm1).

	Luau's `math` library has no `expm1`. This one uses Kahan's correction, so it
	stays accurate for `x` near `0`, where `exp(x) - 1` would cancel to zero.
]=]

const Number = require("../Number")

--[=[
	@within expm1
	@param x any -- the value whose `e^x - 1` to return
	@return number -- `exp(x) - 1`. `-1` as `x` goes to `-Infinity`.
]=]
const function expm1(x: any): number
	const value: number = Number(x)
	if value ~= value then
		return value
	end
	const u: number = math.exp(value)
	if u == Number.POSITIVE_INFINITY then
		return Number.POSITIVE_INFINITY
	end
	if u == 1 then
		return value
	end
	if u - 1 == -1 then
		return -1
	end
	return (u - 1) * value / math.log(u)
end

return expm1
