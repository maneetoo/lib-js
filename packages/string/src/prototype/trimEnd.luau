--!strict

--[=[
	@class trimEnd

	A Luau implementation of JavaScript's [`String.prototype.trimEnd()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/trimEnd).

	Removes whitespace from the end of a string. `trimRight` is the same
	function.
]=]

const __shared = require("../__shared")
const __utf8 = require("../__utf8")

--[=[
	@within trimEnd
	@param self unknown -- the string to trim
	@return string -- the string without trailing whitespace

	Whitespace is defined as in `trim`.
]=]
const function trimEnd(self: unknown): string
	const s = __shared.thisString(self, "trimEnd")
	if __utf8.isAscii(s) then
		return string.match(s, "^(.-)%s*$") :: string
	end

	const codePoints = __utf8.decode(s)
	local last = #codePoints
	while last >= 1 and __shared.isWhitespace(codePoints[last]) do
		last -= 1
	end
	return __utf8.encode(codePoints, 1, last)
end

return trimEnd
