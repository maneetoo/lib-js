--!strict

--[=[
	@class substr

	A Luau implementation of JavaScript's [`String.prototype.substr()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/substr).

	Extracts a part of a string by start and length. This method is
	deprecated in JavaScript, but it remains part of the standard. Prefer
	`slice` or `substring` in new code.
]=]

const ECMAScript = require "../../ECMAScript"
const __shared = require "../__shared"
const __utf8 = require "../__utf8"

--[=[
	@within substr
	@param self unknown -- the string to cut
	@param start unknown -- the first code point index; a negative value counts from the end
	@param length unknown -- how many code points to take (default: the rest of the string)
	@return string -- the extracted part, or `""` when nothing is taken
]=]
const function substr(self: unknown, start: unknown, count: unknown): string
	const s = __shared.thisString(self, "substr")
	const size = __utf8.length(s)
	const from = ECMAScript.ToClampedIndexOrDefault(start, size, 0)
	const taken = if count == nil then size else __shared.clamp(ECMAScript.ToIntegerOrInfinity(count), 0, size)
	const to = math.min(from + taken, size)
	return __utf8.sub(s, from, to)
end

return substr
