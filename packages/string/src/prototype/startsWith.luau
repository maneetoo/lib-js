--!strict

--[=[
	@class startsWith

	A Luau implementation of JavaScript's [`String.prototype.startsWith()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/startsWith).

	Checks whether a string begins with a given substring.
]=]

const ECMAScript = require "../../ECMAScript"
const __shared = require "../__shared"
const __utf8 = require "../__utf8"

--[=[
	@within startsWith
	@param self unknown -- the string to test
	@param search unknown -- the substring to look for
	@param position unknown -- the code point index where the check starts (default `0`)
	@return boolean -- `true` if `search` occurs at `position`

	:::caution
	Regular expressions are not supported. A pattern argument is converted
	to a string and matched literally.
	:::
]=]
const function startsWith(self: unknown, search: unknown, position: unknown): boolean
	const s = __shared.thisString(self, "startsWith")
	const pattern = ECMAScript.ToString(search)
	const length = __utf8.length(s)
	const start = __shared.clamp(ECMAScript.ToIntegerOrInfinity(position), 0, length)
	return __utf8.sub(s, start, start + __utf8.length(pattern)) == pattern
end

return startsWith
