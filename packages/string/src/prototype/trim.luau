--!strict

--[=[
	@class trim

	A Luau implementation of JavaScript's [`String.prototype.trim()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/trim).

	Removes whitespace from both ends of a string.
]=]

const __shared = require "../__shared"
const __utf8 = require "../__utf8"

--[=[
	@within trim
	@param self unknown -- the string to trim
	@return string -- the string without leading and trailing whitespace

	Whitespace is ASCII whitespace, plus the Unicode space characters and the
	byte-order mark, as JavaScript defines it.
]=]
const function trim(self: unknown): string
	const s = __shared.thisString(self, "trim")
	if __utf8.isAscii(s) then
		return string.match(s, "^%s*(.-)%s*$") :: string
	end

	const codePoints = __utf8.decode(s)
	local first = 1
	local last = #codePoints
	while first <= last and __shared.isWhitespace(codePoints[first]) do
		first += 1
	end
	while last >= first and __shared.isWhitespace(codePoints[last]) do
		last -= 1
	end
	return __utf8.encode(codePoints, first, last)
end

return trim
