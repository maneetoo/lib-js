--!strict

--[=[
	@class toString

	A Luau implementation of JavaScript's
	[`Number.prototype.toString()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/toString).

	Converts a number to a string, optionally in a radix other than 10.
]=]

const __shared = require("./__shared")
const toExponential = require("./toExponential")

const DIGITS: string = "0123456789abcdefghijklmnopqrstuvwxyz"

const function integerToBase(n: number, radix: number): string
	if n == 0 then
		return "0"
	end

	const digits: { string } = {}
	local value: number = n

	while value > 0 do
		const digit: number = value % radix
		table.insert(digits, 1, DIGITS:sub(digit + 1, digit + 1))
		value = math.floor(value / radix)
	end

	return table.concat(digits)
end

--[=[
	@within toString
	@param self number -- the number to convert
	@param radix number? -- the base to convert to, from `2` to `36` (default `10`)
	@return string -- `self` rendered as a string in the given radix

	With `radix` omitted (or `10`), produces the same decimal text
	JavaScript's own default number-to-string conversion would — plain
	digits for integers, a decimal point for fractional values, and
	exponential notation for very large (`>= 1e21`) or very small
	(`< 1e-6`, nonzero) magnitudes.

	With any other `radix`, converts `self` into that base instead:
	digits `0`-`9` then letters `a`-`z` for digit values above `9`,
	matching e.g. `toString(255, 16)` → `"ff"`.

	:::caution
	`radix` must be an integer from `2` to `36` inclusive — anything
	else raises an error, mirroring the `RangeError` JavaScript throws
	for an out-of-range radix.
	:::

	:::caution
	Non-decimal radixes only faithfully convert the integer part. A
	fractional value converted to a non-10 radix includes a best-effort
	fractional digit string (up to 52 digits — the number of bits in a
	double's mantissa), but makes no attempt to find the *shortest*
	fractional digit string that round-trips back to `self`, the way
	the decimal path does.
	:::

	:::note
	Decimal output's "shortest round-trip" digit count is an
	approximation — see this module's internal `__shared.shortestDigits`
	for details and caveats.
	:::
]=]
const function toString(self: number, radix: number?): string
	const specialCase = __shared.special(self)
	if specialCase then
		return specialCase
	end

	const base = radix or 10
	if base ~= math.floor(base) or base < 2 or base > 36 then
		error("toString: radix must be an integer between 2 and 36", 2)
	end

	const negative, magnitude = __shared.signAndMagnitude(self)
	const sign = if negative then "-" else ""

	if base ~= 10 then
		const integerPart = math.floor(magnitude)
		const fractionalPart = magnitude - integerPart
		local text = integerToBase(integerPart, base)

		if fractionalPart > 0 then
			const fractionDigits = {}
			local remaining = fractionalPart

			for _ = 1, 52 do
				if remaining <= 0 then
					break
				end
				remaining *= base
				const digit = math.floor(remaining)
				table.insert(fractionDigits, DIGITS:sub(digit + 1, digit + 1))
				remaining -= digit
			end

			if #fractionDigits > 0 then
				text ..= "." .. table.concat(fractionDigits)
			end
		end

		return sign .. text
	end

	if magnitude == 0 then
		return "0"
	end

	const digits, exponent = __shared.shortestDigits(magnitude)

	if exponent >= 21 or exponent < -6 then
		return toExponential(self)
	end

	return sign .. __shared.placeDecimalPoint(digits, exponent)
end

return toString
