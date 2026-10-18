--!strict

--[=[
	@class parseFloat

	A Luau implementation of JavaScript's
	[`Number.parseFloat()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/parseFloat).

	Parses a leading floating-point literal out of a string, ignoring
	any trailing content, rather than requiring the *entire* string to
	be a valid number the way Luau's own `tonumber` does.
]=]

const function isDigit(character: string): boolean
	return character >= "0" and character <= "9"
end

--[=[
	@within parseFloat
	@param input string -- the string to parse
	@return number -- the leading numeric value found, or `NaN` if none was found

	Skips leading whitespace, then reads as much of the remaining text
	as forms a valid decimal literal — optional sign, integer digits,
	an optional fractional part, and an optional exponent — stopping at
	the first character that doesn't fit, exactly like JS's
	`parseFloat`. Anything after that point is ignored rather than
	causing an error, so `parseFloat("3.14abc")` is `3.14`, not `NaN`.

	Returns `NaN` if no valid number could be read at all (an empty
	string, pure whitespace, or text with no leading digits).

	:::note
	`"Infinity"` (optionally signed) is recognized up front as its own
	special case, matching JS: `parseFloat("Infinity")` is `math.huge`,
	not `NaN`.
	:::

	:::caution
	Unlike JavaScript's `parseFloat`, which first coerces its argument
	to a string via `ToString` (so `parseFloat(3.5)` or even
	`parseFloat({ toString = ... })` both work), this function requires
	an actual Luau `string` — pass `tostring(value)` yourself first if
	`value` isn't already one.
	:::

	:::caution
	Leading whitespace is matched with Luau's `%s` pattern class
	(spaces, tabs, newlines, etc.), which covers ASCII whitespace but
	not every exotic Unicode whitespace character JS's own, broader
	definition recognizes.
	:::
]=]
const function parseFloat(input: string): number
	const length = #input
	local i = 1

	while i <= length and input:sub(i, i):match("%s") do
		i += 1
	end

	const start = i

	if input:sub(i, i) == "+" or input:sub(i, i) == "-" then
		i += 1
	end

	if input:sub(i, i + 7) == "Infinity" then
		return if input:sub(start, start) == "-" then -math.huge else math.huge
	end

	local sawDigit = false

	while i <= length and isDigit(input:sub(i, i)) do
		sawDigit = true
		i += 1
	end

	if input:sub(i, i) == "." then
		i += 1
		while i <= length and isDigit(input:sub(i, i)) do
			sawDigit = true
			i += 1
		end
	end

	if not sawDigit then
		return 0 / 0
	end

	-- An exponent is only consumed if it's actually followed by at
	-- least one digit — a trailing bare "e"/"e+" with no digits isn't
	-- part of the number, matching JS (`parseFloat("1e")` is `1`, not
	-- `NaN`, and the dangling "e" is simply left unconsumed).
	if input:sub(i, i) == "e" or input:sub(i, i) == "E" then
		local j = i + 1
		if input:sub(j, j) == "+" or input:sub(j, j) == "-" then
			j += 1
		end
		const exponentDigitsStart = j
		while j <= length and isDigit(input:sub(j, j)) do
			j += 1
		end
		if j > exponentDigitsStart then
			i = j
		end
	end

	return tonumber(input:sub(start, i - 1)) :: number
end

return parseFloat
