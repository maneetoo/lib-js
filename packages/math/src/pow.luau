--!strict

--[=[
	@class pow

	A Luau implementation of JavaScript's
	[`Math.pow()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/pow).

	Luau's `math.pow` (and the `^` operator) differ here: `1 ^ NaN` is `1` and
	`(-1) ^ Infinity` is `1`. JavaScript gives `NaN` for both.
]=]

const Number = require("../Number")

--[=[
	@within pow
	@param base any -- the base
	@param exponent any -- the exponent
	@return number -- `base` raised to `exponent`, the same as JavaScript's `**`

	:::note
	`x ** NaN` is `NaN`, even for `x == 1`. `±1 ** ±Infinity` is `NaN`.
	`x ** 0` is `1` for every `x`, including `NaN`.
	:::
]=]
const function pow(base: any, exponent: any): number
	const b: number, e: number = Number(base), Number(exponent)
	if e ~= e then
		return Number.NaN
	end
	if (b == 1 or b == -1) and (e == Number.POSITIVE_INFINITY or e == Number.NEGATIVE_INFINITY) then
		return Number.NaN
	end
	return b ^ e
end

return pow
