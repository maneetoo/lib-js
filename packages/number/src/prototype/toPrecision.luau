--!strict

--[=[
	@class toPrecision

	A Luau implementation of JavaScript's
	[`Number.prototype.toPrecision()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/toPrecision).

	Formats a number to a given number of significant digits, choosing
	fixed-point or exponential notation automatically based on the
	number's magnitude.
]=]

const __shared = require("./__shared")
const toExponential = require("./toExponential")
const toString = require("./toString")

--[=[
	@within toPrecision
	@param self number -- the number to format
	@param precision number? -- how many significant digits to show
	@return string -- `self` formatted to `precision` significant digits

	With `precision` omitted, this is equivalent to plain `toString()`.
	Otherwise, returns `self` rendered with exactly `precision`
	significant digits, switching to exponential notation whenever the
	(post-rounding) exponent falls outside `[-6, precision)` —
	precisely JavaScript's own switchover rule.

	:::caution
	`precision` must be an integer from `1` to `100` inclusive —
	anything else raises an error, mirroring the `RangeError`
	JavaScript throws for an out-of-range precision.
	:::
]=]
const function toPrecision(self: number, precision: number?): string
	if precision == nil then
		return toString(self)
	end

	const specialCase = __shared.special(self)
	if specialCase then
		return specialCase
	end

	if precision ~= math.floor(precision) or precision < 1 or precision > 100 then
		error("toPrecision: precision must be an integer between 1 and 100", 2)
	end

	const negative, magnitude = __shared.signAndMagnitude(self)
	const sign = if negative then "-" else ""

	if magnitude == 0 then
		if precision == 1 then
			return `{sign}0`
		end
		return `{sign}0.{string.rep("0", precision - 1)}`
	end

	-- `exponent` already reflects any carry from rounding to `precision`
	-- significant digits, since it comes straight out of
	-- `string.format("%e", ...)`, which performs that rounding itself.
	const mantissa, exponent = __shared.exponential(magnitude, precision - 1)

	if exponent < -6 or exponent >= precision then
		return toExponential(self, precision - 1)
	end

	const digits = (mantissa:gsub("%.", ""))
	return sign .. __shared.placeDecimalPoint(digits, exponent)
end

return toPrecision
