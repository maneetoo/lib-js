--!strict

--[=[
	@class charAt

	A Luau implementation of JavaScript's [`String.prototype.charAt()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/charAt).

	Returns the character at an index, or an empty string.
]=]

const ECMAScript = require "../../ECMAScript"
const __shared = require "../__shared"
const __utf8 = require "../__utf8"

--[=[
	@within charAt
	@param self unknown -- the string to read from
	@param position unknown -- the code point index (default `0`)
	@return string -- the character, or `""` when the index is out of range

	:::caution
	Unlike `at`, a negative index does not count from the end. It gives `""`.
	:::
]=]
const function charAt(self: unknown, position: unknown): string
	const s = __shared.thisString(self, "charAt")
	const index = ECMAScript.ToIntegerOrInfinity(position)
	if index < 0 or index >= __utf8.length(s) then
		return ""
	end
	return __utf8.sub(s, index, index + 1)
end

return charAt
