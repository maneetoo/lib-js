--!strict

--[=[
	@class NumberFormattingShared
	@private

	Internal helpers shared by `toExponential`, `toFixed`, `toPrecision`,
	and `toString`: handling the `NaN`/`Infinity` special cases every
	one of them needs to handle identically, splitting a number into
	sign/magnitude, and converting between a number and its decomposed
	"significant digits + exponent" form.

	:::note
	This module is not part of the public `Number` surface — it exists
	purely to avoid re-deriving the same few steps across four very
	similar formatting functions.
	:::
]=]

--[=[
	Returns `"NaN"`, `"Infinity"`, or `"-Infinity"` for the
	corresponding special values, or `nil` for any ordinary finite
	number — a `nil` result means "keep formatting normally".
]=]
const function special(x: number): string?
	if x ~= x then
		return "NaN"
	end
	if x == math.huge then
		return "Infinity"
	end
	if x == -math.huge then
		return "-Infinity"
	end
	return nil
end

--[=[
	Splits `x` into a `(negative, magnitude)` pair. `negative` follows
	JavaScript's own sign test (`x < 0`), under which `-0` is *not*
	negative, matching how `(-0).toFixed(2)` is `"0.00"`, not `"-0.00"`.
]=]
const function signAndMagnitude(x: number): (boolean, number)
	const negative = x < 0
	return negative, if negative then -x else x
end

--[=[
	Formats the positive, finite, nonzero `magnitude` with exactly
	`fractionDigits` digits after the mantissa's decimal point (i.e.
	`fractionDigits + 1` significant digits total), delegating the
	actual decimal rounding to `string.format("%e", ...)` — which wraps
	the platform C library's `printf`, correctly handling the "rounds up
	and carries into an extra digit" case (e.g. rounding `9.996` to 3
	significant digits yields mantissa `"1.00"` *and* an exponent bumped
	up by one, both produced correctly by `%e` itself, with no manual
	carry-handling needed here).

	Returns the mantissa text (e.g. `"1.23"`, or just `"1"` when
	`fractionDigits` is `0`) and the exponent as a plain integer
	(un-padded, no sign character baked in).
]=]
const function exponential(magnitude: number, fractionDigits: number): (string, number)
	const formatted = string.format(`%.{fractionDigits}e`, magnitude)
	const mantissa, exponentText = formatted:match("^(%d[%.%d]*)e([%+%-]%d+)$")
	return mantissa :: string, tonumber(exponentText :: string) :: number
end

--[=[
	Approximates JavaScript's "shortest digit string that round-trips
	back to this exact number" by formatting with 17 significant digits
	(enough to round-trip any IEEE-754 double) and trimming trailing
	zeros. Returns the trimmed significant-digit string (no decimal
	point, e.g. `"125"`) and the base-10 exponent of its first digit.

	:::caution
	This is only an approximation of true shortest-round-trip digit
	selection — real engines reason about the two neighbouring
	representable doubles to find the *provably* shortest digit string,
	which needs arbitrary-precision decimal arithmetic to do exactly.
	This cheaper approximation matches JavaScript for the vast majority
	of values, but can occasionally keep one digit more than a real
	engine would.
	:::
]=]
const function shortestDigits(magnitude: number): (string, number)
	const mantissa, exponent = exponential(magnitude, 16)
	local digits = (mantissa:gsub("%.", ""))
	digits = (digits:gsub("0+$", ""))
	if digits == "" then
		digits = "0"
	end
	return digits, exponent
end

--[=[
	Reconstructs a fixed-point (non-exponential) numeric string from a
	bare significant-digit string and the base-10 exponent of its first
	digit — the inverse of splitting a number into "digits" + "exponent
	of the leading digit". Used to turn an exponential-style
	digits/exponent pair back into plain fixed-point notation.
]=]
const function placeDecimalPoint(digits: string, exponent: number): string
	const length = #digits

	if exponent >= 0 then
		const integerLength = exponent + 1
		if integerLength >= length then
			return digits .. string.rep("0", integerLength - length)
		end
		return digits:sub(1, integerLength) .. "." .. digits:sub(integerLength + 1)
	end

	return "0." .. string.rep("0", -exponent - 1) .. digits
end

return table.freeze {
    special = special,
    signAndMagnitude = signAndMagnitude,
    exponential = exponential,
    shortestDigits = shortestDigits,
    placeDecimalPoint = placeDecimalPoint,
}
