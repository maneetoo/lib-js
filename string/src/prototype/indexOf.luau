--!strict

--[=[
	@class indexOf

	A Luau implementation of JavaScript's [`String.prototype.indexOf()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/indexOf).

	Finds the first occurrence of a substring.
]=]

const ECMAScript = require "../../ECMAScript"
const __shared = require "../__shared"
const __toString = require "../__toString"
const __utf8 = require "../__utf8"

--[=[
	@within indexOf
	@param self unknown -- the string to search in
	@param search unknown -- the substring to look for
	@param position unknown -- the code point index to start from (default `0`)
	@return number -- the code point index of the first match, or `-1`

	An empty `search` matches at `position`, clamped to the string length.

	:::caution
	Indices count code points, not UTF-16 units. See `String`'s class docs.
	:::
]=]
const function indexOf(self: unknown, search: unknown, position: unknown): number
	const s = __shared.thisString(self, "indexOf")
	const pattern = __toString(search)
	const start = __shared.clamp(ECMAScript.ToIntegerOrInfinity(position), 0, __utf8.length(s))
	return __utf8.find(s, pattern, start)
end

return indexOf
