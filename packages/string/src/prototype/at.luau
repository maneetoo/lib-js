--!strict

--[=[
	@class at

	A Luau implementation of JavaScript's [`String.prototype.at()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/at).

	Returns the character at an index. Negative indices count from the end.
]=]

const ECMAScript = require "../../ECMAScript"
const __shared = require "../__shared"
const __utf8 = require "../__utf8"

--[=[
	@within at
	@param self unknown -- the string to read from
	@param index unknown -- the code point index; a negative value counts from the end
	@return string? -- the character, or `nil` when the index is out of range

	:::note
	Indices count code points, not UTF-16 units. See `String`'s class docs.
	:::
]=]
const function at(self: unknown, index: unknown): string?
	const s = __shared.thisString(self, "at")
	const length = __utf8.length(s)
	const relative = ECMAScript.ToIntegerOrInfinity(index)
	const position = if relative >= 0 then relative else length + relative
	if position < 0 or position >= length then
		return nil
	end
	return __utf8.sub(s, position, position + 1)
end

return at
