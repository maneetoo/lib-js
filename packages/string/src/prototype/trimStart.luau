--!strict

--[=[
	@class trimStart

	A Luau implementation of JavaScript's [`String.prototype.trimStart()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/trimStart).

	Removes whitespace from the start of a string. `trimLeft` is the same
	function.
]=]

const __shared = require "../__shared"
const __utf8 = require "../__utf8"

--[=[
	@within trimStart
	@param self unknown -- the string to trim
	@return string -- the string without leading whitespace

	Whitespace is defined as in `trim`.
]=]
const function trimStart(self: unknown): string
	const s = __shared.thisString(self, "trimStart")
	if __utf8.isAscii(s) then
		return string.match(s, "^%s*(.*)$") :: string
	end

	const codePoints = __utf8.decode(s)
	local first = 1
	while first <= #codePoints and __shared.isWhitespace(codePoints[first]) do
		first += 1
	end
	return __utf8.encode(codePoints, first, #codePoints)
end

return trimStart
