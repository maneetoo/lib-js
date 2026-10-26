--!strict

--[=[
	@class toFixed

	A Luau implementation of JavaScript's
	[`Number.prototype.toFixed()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/toFixed).

	Formats a number using fixed-point notation, with a set number of
	digits after the decimal point.
]=]

const __shared = require("./__shared")
const toString = require("./toString")

--[=[
	@within toFixed
	@param self number -- the number to format
	@param digits number? -- how many digits to show after the decimal point (default `0`)
	@return string -- `self` formatted in fixed-point notation

	Returns a string with exactly `digits` digits after the decimal
	point (and no decimal point at all when `digits` is `0`), e.g.
	`toFixed(3.14159, 2)` → `"3.14"`, `toFixed(5, 2)` → `"5.00"`.

	:::caution
	`digits` must be an integer from `0` to `100` inclusive — anything
	else raises an error, mirroring the `RangeError` JavaScript throws
	for an out-of-range digit count.
	:::

	:::caution
	For `|self| >= 1e21`, JavaScript falls back to the same
	representation `toString()` would produce, ignoring `digits`
	entirely — fixed-point notation stops being meaningful at that
	scale. This function does the same, deferring to this module's
	`toString`.
	:::

	:::note
	Rounding for the final digit is delegated to Luau's own
	`string.format("%.<n>f", ...)`, which in practice rounds based on
	the number's exact binary value rather than a fixed tie-breaking
	rule. This matches JavaScript's own rounding almost always, since
	exact decimal ties are rare for binary floating-point values, but
	the two are not guaranteed to agree on the rare value where a tie
	genuinely occurs.
	:::
]=]
const function toFixed(self: number, digits: number?): string
	const specialCase = __shared.special(self)
	if specialCase then
		return specialCase
	end

	const digitCount = digits or 0
	if digitCount ~= math.floor(digitCount) or digitCount < 0 or digitCount > 100 then
		error("toFixed: digits must be an integer between 0 and 100", 2)
	end

	const negative, magnitude = __shared.signAndMagnitude(self)
	if magnitude >= 1e21 then
		return toString(self)
	end

	const sign = if negative then "-" else ""
	return `{sign}{string.format(`%.{digitCount}f`, magnitude)}`
end

return toFixed
