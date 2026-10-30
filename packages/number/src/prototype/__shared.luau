--!strict

--[=[
	@class __shared
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
	Number of digits kept by the internal `%.{n}e` expansion used by
	`shortestDigits`. 31 significant digits is comfortably more than the
	21 that a double can actually need (see `shortestDigits` for why the
	extra headroom is free): the expansion only has to be *correctly
	rounded* and long enough for every candidate test below to be exact.
]=]
const SOURCE_DIGITS = 30

--[=[
	Upper bound on the number of significant digits `shortestDigits` may
	return. Every finite double has a decimal representation with at most
	17 significant digits that reads back as the same double, so the
	search never needs to look further.
]=]
const MAX_DIGITS = 17

const bits = buffer.create(8)

--[=[
	@within __shared
	@private
	@param x number -- the number to test
	@return string? --

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
	@within __shared
	@private
	@param x number -- the number to split
	@return (boolean, number) -- a tuple of `(negative, magnitude)`

	Splits `x` into a `(negative, magnitude)` pair. `negative` follows
	JavaScript's own sign test (`x < 0`), under which `-0` is *not*
	negative, matching how `(-0).toFixed(2)` is `"0.00"`, not `"-0.00"`.
]=]
const function signAndMagnitude(x: number): (boolean, number)
	const negative = x < 0
	return negative, if negative then -x else x
end

--[=[
	@within __shared
	@private
	@param magnitude number -- a positive, finite, nonzero number
	@param fractionDigits number -- the number of digits after the decimal point to keep
	@return (string, number) -- a tuple of `(mantissa, exponent)`

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
	@within __shared
	@private
	@param m number -- a positive, finite, nonzero number
	@return number -- the unit in the last place of `m`

	Returns the unit in the last place of the positive, finite,
	non-subnormal-or-subnormal `m` — the distance between `m` and the
	next representable double above it. Read straight out of the
	exponent field of the IEEE-754 bit pattern: for normal numbers the
	ulp is `2^(biasedExponent - 1075)`, and every subnormal shares the
	same absolute ulp of `2^-1074`.
]=]
const function ulpOf(m: number): number
	buffer.writef64(bits, 0, m)
	const biasedExponent = (buffer.readu32(bits, 4) // 0x100000) % 0x800
	if biasedExponent == 0 then
		return 2 ^ -1074
	end
	return 2 ^ (biasedExponent - 1075)
end

--[=[
	@within __shared
	@private
	@param digits string -- a string of digits
	@return string -- the digit string with trailing zeros stripped

	Strips trailing zeros from a bare digit string, which is what turns
	"17 digits that round-trip" into "the fewest digits that still
	round-trip". A string of nothing but zeros collapses to `"0"`.
]=]
const function trimTrailingZeros(digits: string): string
	const trimmed = (digits:gsub("0+$", ""))
	if trimmed == "" then
		return "0"
	end
	return trimmed
end

--[=[
	@within __shared
	@private
	@param digits string -- a string of digits
	@param exponent number -- the base-10 exponent of the first digit
	@param magnitude number -- the original number
	@return boolean -- `true` if the candidate round-trips back to `magnitude`

	Compares the candidate `digits × 10^(exponent - #digits + 1)` against
	`magnitude` by handing both to `tonumber`, whose decimal-to-double
	conversion is correctly rounded. An exact comparison, no tolerance
	and no rounding of our own involved — this is what makes the search
	below exact rather than an approximation.
]=]
const function roundTrips(digits: string, exponent: number, magnitude: number): boolean
	return tonumber(`{digits}e{exponent - #digits + 1}`) == magnitude
end

--[=[
	@within __shared
	@private
	@param source string -- a string of digits
	@param k number -- the index of the last digit to increment
	@return (string, number) -- a tuple of `(incrementedDigits, exponentShift)

	Returns `source[1..k] + 1` as a digit string, together with the shift
	that has to be applied to the exponent: incrementing a run of nines
	can lengthen the number (`"999" + 1 = "1000"`), and in that case the
	returned digits are `"1"` and the shift is `+1` rather than four
	digits of `"1000"`.
]=]
const function incrementAt(source: string, k: number): (string, number)
	const lastByte = source:byte(k) :: number
	if lastByte ~= 57 then
		return source:sub(1, k - 1) .. string.char(lastByte + 1), 0
	end

	local index = k
	while index >= 1 and source:byte(index) == 57 do
		index -= 1
	end

	if index == 0 then
		return "1", 1
	end

	return source:sub(1, index - 1) .. string.char((source:byte(index) :: number) + 1) .. string.rep("0", k - index), 0
end

--[=[
	@within __shared
	@private
	@param source string -- a string of digits
	@param k number -- the index of the last digit to decrement
	@return string -- the decremented digit string

	Returns `source[1..k] - 1` as a digit string. Returns `"0"` when the
	subtraction would fall below `10^(k-1)` (i.e. when `source[1..k]` is
	`"1"` followed by zeros): such a value is not a k-digit number any
	more and is never a usable candidate.
]=]
const function decrementAt(source: string, k: number): string
	const lastByte = source:byte(k) :: number
	if lastByte ~= 48 then
		return source:sub(1, k - 1) .. string.char(lastByte - 1)
	end

	local index = k
	while index >= 1 and source:byte(index) == 48 do
		index -= 1
	end

	if index == 0 then
		return "0"
	end
	if index == 1 and source:byte(1) == 49 then
		return string.rep("9", k - 1)
	end

	return source:sub(1, index - 1) .. string.char((source:byte(index) :: number) - 1) .. string.rep("9", k - index)
end

--[=[
	@within __shared
	@private
	@param magnitude number -- a positive, finite, nonzero number
	@return (string, number) -- a tuple of `(digits, exponent)`

	JavaScript's "shortest digit string that round-trips back to this
	exact number": the minimum number of significant digits `k` such that
	some `k`-digit decimal reads back as `magnitude`, choosing — among
	the candidates of that length — the one closest to `magnitude`, and
	the one with an even last digit when two are exactly equidistant (the
	tie-break ECMA-262 prescribes). Returns the digit string with
	trailing zeros removed (no decimal point, e.g. `"125"`) and the
	base-10 exponent of its first digit.

	The search is exact for every finite double, not an approximation of
	JavaScript's answer:

	* one correctly rounded 31-digit expansion of `magnitude` (`%.{30}e`)
	  is enough source material — every `k`-digit candidate in range is a
	  prefix of it, possibly incremented or decremented;
	* for a given `k` the only `k`-digit decimals that can possibly read
	  back as `magnitude` are the three grid points around it — the
	  truncation, the one above, and the one below — because a decimal
	  that reads back must lie inside the rounding interval of
	  `magnitude`, whose width is one ulp;
	* the cheap test in front of each candidate only ever *rejects* what
	  is provably outside that interval: the truncation is at distance
	  `f >= 10^-(zeros + 1)` and the neighbour above at `1 - f >=
	  10^-(nines + 1)`, so a candidate whose lower-bound distance already
	  exceeds `ulp / step` cannot round-trip and is skipped without
	  reading anything back;
	* every surviving candidate is then confirmed with `roundTrips`, whose
	  `tonumber` is correctly rounded. A wrong digit string is therefore
	  impossible; if the loop ever ran out (it does not, `k = 17` always
	  succeeds) the truncation at `MAX_DIGITS` is returned.

	Cost: one `%.{30}e`, ~16 arithmetic-only filter steps and about 2.5
	`tonumber` reads per number, since the filter skips nearly all of the
	17 candidate lengths. No big-integer arithmetic anywhere.
]=]
const function shortestDigits(magnitude: number): (string, number)
	const mantissa, exponent = exponential(magnitude, SOURCE_DIGITS)
	const source = (mantissa:gsub("%.", ""))
	const length = #source
	const ulp = ulpOf(magnitude)
	const limit = math.min(MAX_DIGITS, length)

	for k = 1, limit do
		const step = 10 ^ (exponent - k + 1)
		-- reach = ulp / step: a candidate may only round-trip when its distance
		-- from `magnitude`, measured in steps of the k-digit grid, is at most
		-- `reach`. A full ulp (instead of half a gap) keeps the filter generous.
		const reach = if step == 0 then math.huge else ulp / step
		const alwaysPossible = reach >= 1
		const logReach = if alwaysPossible then 0 else -math.log(reach, 10)

		-- 0.tail >= 10^-(zeros + 1), so the truncation is impossible once that
		-- lower bound already exceeds `reach`.
		const firstNonZero = source:find("[^0]", k + 1)
		const zeros = if firstNonZero == nil then length - k else firstNonZero - (k + 1)
		const samePossible = alwaysPossible or firstNonZero == nil or zeros + 1 >= logReach

		-- 1 - 0.tail >= 10^-(nines + 1), where `nines` counts the leading nines
		-- of the tail: the same bound for the neighbour above.
		const firstNotNine = if alwaysPossible then nil else source:find("[^9]", k + 1)
		const nines = if firstNotNine == nil then length - k else firstNotNine - (k + 1)
		const upPossible = alwaysPossible or nines + 1 >= logReach

		if not (samePossible or upPossible) then
			continue
		end

		-- which neighbour is nearer: decided by the remaining source digits,
		-- with an exactly-halfway tail resolved towards the even last digit
		const tailDigit = source:sub(k + 1, k + 1)
		local upFirst: boolean
		if tailDigit == "" or tailDigit < "5" then
			upFirst = false
		elseif tailDigit > "5" then
			upFirst = true
		else
			upFirst = source:find("[^0]", k + 2) ~= nil or (source:byte(k) :: number) % 2 == 1
		end

		-- nearest first, then the other one; each is only tested when the
		-- filter above says it can round-trip at all
		for pass = 1, 2 do
			if (pass == 1) == upFirst then
				if upPossible then
					const up, shift = incrementAt(source, k)
					if roundTrips(up, exponent + shift, magnitude) then
						return trimTrailingZeros(up), exponent + shift
					end
				end
			elseif samePossible then
				const head = source:sub(1, k)
				if roundTrips(head, exponent, magnitude) then
					return trimTrailingZeros(head), exponent
				end
			end
		end

		-- the far neighbour: only reachable when 1 + f <= reach, which needs
		-- `samePossible` to hold in the first place
		if k >= 2 and samePossible then
			const below = decrementAt(source, k)
			if below ~= "0" and roundTrips(below, exponent, magnitude) then
				return trimTrailingZeros(below), exponent
			end
		end
	end

	return trimTrailingZeros(source:sub(1, MAX_DIGITS)), exponent
end

--[=[
	@within __shared
	@private
	@param digits string -- a string of digits
	@param exponent number -- the base-10 exponent of the first digit
	@return string -- a fixed-point numeric string
	
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

return table.freeze({
	special = special,
	signAndMagnitude = signAndMagnitude,
	exponential = exponential,
	shortestDigits = shortestDigits,
	placeDecimalPoint = placeDecimalPoint,
})
