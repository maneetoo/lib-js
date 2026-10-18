--!strict

--[=[
	@class parseInt

	A Luau implementation of JavaScript's
	[`Number.parseInt()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/parseInt).

	Parses a leading integer literal out of a string in a given radix,
	ignoring any trailing content.
]=]

-- A lookup from digit character (both cases, for radixes above 10) to
-- its numeric value, built once at module load time rather than
-- recomputed per call.
const DIGIT_VALUES: { [string]: number } = {}
for i = 0, 9 do
	DIGIT_VALUES[tostring(i)] = i
end
for i = 0, 25 do
	DIGIT_VALUES[string.char(97 + i)] = 10 + i -- 'a'..'z'
	DIGIT_VALUES[string.char(65 + i)] = 10 + i -- 'A'..'Z'
end

--[=[
	@within parseInt
	@param input string -- the string to parse
	@param radix number? -- the base to parse in, from `2` to `36` (default `10`, or `16` if a `"0x"`/`"0X"` prefix is present)
	@return number -- the leading integer value found, or `NaN` if none was found

	Skips leading whitespace, reads an optional sign, then — if `radix`
	is omitted (or `0`) and the text starts with `"0x"`/`"0X"` — treats
	the number as hexadecimal and consumes that prefix. Otherwise
	defaults to base `10`. Digits valid for the resulting radix are then
	read greedily, stopping at the first character that doesn't belong,
	exactly like JS's `parseInt`: `parseInt("10px")` is `10`, not `NaN`.

	Returns `NaN` if `radix` is out of the `2`-`36` range, or if no
	valid digit for the resulting radix could be read at all.

	:::caution
	The `"0x"`/`"0X"` prefix is only recognized (and consumed) when
	`radix` is omitted/`0`, or explicitly `16` — matching JS exactly.
	Passing an explicit radix of, say, `10` does **not** strip the
	prefix: `parseInt("0x10", 10)` reads only the leading `"0"` and
	stops at `"x"`, returning `0`, not `16`.
	:::

	:::caution
	Unlike JavaScript's `parseInt`, which first coerces its argument to
	a string via `ToString`, this function requires an actual Luau
	`string` — pass `tostring(value)` yourself first if needed.
	:::
]=]
const function parseInt(input: string, radix: number?): number
	const length = #input
	local i = 1

	while i <= length and input:sub(i, i):match("%s") do
		i += 1
	end

	local negative = false
	if input:sub(i, i) == "-" then
		negative = true
		i += 1
	elseif input:sub(i, i) == "+" then
		i += 1
	end

	local base = radix or 0
	if base ~= 0 and (base ~= math.floor(base) or base < 2 or base > 36) then
		return 0 / 0
	end

	const hasHexPrefix = input:sub(i, i + 1) == "0x" or input:sub(i, i + 1) == "0X"

	if base == 0 then
		if hasHexPrefix then
			base = 16
			i += 2
		else
			base = 10
		end
	elseif base == 16 and hasHexPrefix then
		i += 2
	end

	const digitsStart = i
	while i <= length do
		const value = DIGIT_VALUES[input:sub(i, i)]
		if value == nil or value >= base then
			break
		end
		i += 1
	end

	if i == digitsStart then
		return 0 / 0
	end

	local result = 0
	for position = digitsStart, i - 1 do
		result = result * base + (DIGIT_VALUES[input:sub(position, position)] :: number)
	end

	return if negative then -result else result
end

return parseInt
