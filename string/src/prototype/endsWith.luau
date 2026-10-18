--!strict

--[=[
	@class endsWith

	A Luau implementation of JavaScript's [`String.prototype.endsWith()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/endsWith).

	Checks whether the string ends with a given substring.
]=]

const ECMAScript = require "../../ECMAScript"
const __shared = require "../__shared"
const __toString = require "../__toString"
const __utf8 = require "../__utf8"

--[=[
	@within endsWith
	@param self unknown -- the string to test
	@param search unknown -- the substring to look for
	@param endPosition unknown -- only the text before this code point index is considered (default: the whole string)
	@return boolean -- `true` if the text before `endPosition` ends with `search`

	:::caution
	Regular expressions are not supported. A pattern argument is converted
	to a string and matched literally.
	:::
]=]
const function endsWith(self: unknown, search: unknown, endPosition: unknown): boolean
	const s = __shared.thisString(self, "endsWith")
	const pattern = __toString(search)
	const length = __utf8.length(s)
	const finish = if endPosition == nil then length else __shared.clamp(ECMAScript.ToIntegerOrInfinity(endPosition), 0, length)
	const start = finish - __utf8.length(pattern)
	if start < 0 then
		return false
	end
	return __utf8.sub(s, start, finish) == pattern
end

return endsWith
