--!strict

--[=[
	@class toExponential

	A Luau implementation of JavaScript's
	[`Number.prototype.toExponential()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/toExponential).

	Formats a number using exponential ("scientific") notation:
	`d.dddde±dd`.
]=]

const __shared = require "./__shared"

--[=[
	@within toExponential
	@param self number -- the number to format
	@param fractionDigits number? -- how many digits to show after the mantissa's decimal point
	@return string -- `self` formatted in exponential notation

	Returns a string of the form
	`"<sign><digit>.<fractionDigits digits>e<sign><exponent>"`, e.g.
	`toExponential(1234.5, 2)` → `"1.23e+3"`.

	:::caution
	`fractionDigits` must be an integer from `0` to `100` inclusive —
	anything else raises an error, mirroring the `RangeError`
	JavaScript throws for an out-of-range digit count.
	:::

	:::caution
	When `fractionDigits` is omitted, JavaScript picks "as many digits
	as necessary to uniquely represent the number". Luau has no
	built-in shortest-round-trip float formatter, so this approximates
	it — see this module's internal `__shared.shortestDigits` for exactly
	how, and its caveats.
	:::
]=]
const function toExponential(self: number, fractionDigits: number?): string
	const specialCase = __shared.special(self)
	if specialCase then
		return specialCase
	end

	if fractionDigits ~= nil
		and (fractionDigits ~= math.floor(fractionDigits) or fractionDigits < 0 or fractionDigits > 100)
	then
		error("toExponential: fractionDigits must be an integer between 0 and 100", 2)
	end

	const negative, magnitude = __shared.signAndMagnitude(self)
	const sign = if negative then "-" else ""

	if magnitude == 0 then
		const digitCount = fractionDigits or 0
		const mantissa = if digitCount > 0 then "0." .. string.rep("0", digitCount) else "0"
		return `{sign}{mantissa}e+0`
	end

	local mantissaText: string
	local exponent: number

	if fractionDigits ~= nil then
		mantissaText, exponent = __shared.exponential(magnitude, fractionDigits)
	else
		const digits, exp = __shared.shortestDigits(magnitude)
		exponent = exp
		mantissaText = if #digits > 1 then digits:sub(1, 1) .. "." .. digits:sub(2) else digits
	end

	const exponentSign = if exponent < 0 then "-" else "+"
	return `{sign}{mantissaText}e{exponentSign}{math.abs(exponent)}`
end

return toExponential
