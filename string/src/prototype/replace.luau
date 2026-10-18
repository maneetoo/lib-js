--!strict

--[=[
	@class replace

	A Luau implementation of JavaScript's [`String.prototype.replace()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace).

	Replaces the first occurrence of a substring.
]=]

const ECMAScript = require "../../ECMAScript"
const __shared = require "../__shared"
const __toString = require "../__toString"
const __utf8 = require "../__utf8"

--[=[
	@within replace
	@param self unknown -- the string to change
	@param search unknown -- the substring to replace; only the first occurrence is replaced
	@param replaceValue unknown -- a replacement string, or a function
	@return string -- the string with the first match replaced

	A replacement string can use `$$` (a literal `$`), `$&` (the match),
	`` $` `` (the text before the match) and `$'` (the text after it). Any
	other `$` is kept as written.

	A function is called as `replaceValue(match, position, self)`. Its result
	is converted with `ToString`.

	:::caution
	Only string patterns are supported. Regular expressions and `$1`-style
	group references are not.
	:::
]=]
const function replace(self: unknown, search: unknown, replaceValue: unknown): string
	const s = __shared.thisString(self, "replace")
	const pattern = __toString(search)
	const position = __utf8.find(s, pattern, 0)
	if position == -1 then
		return s
	end

	const patternLength = __utf8.length(pattern)
	const length = __utf8.length(s)
	const before = __utf8.sub(s, 0, position)
	const after = __utf8.sub(s, position + patternLength, length)

	local replacement: string
	if ECMAScript.IsCallable(replaceValue) then
		replacement = __toString((replaceValue :: any)(pattern, position, s))
	else
		replacement = __shared.expandReplacement(__toString(replaceValue), pattern, before, after)
	end

	return before .. replacement .. after
end

return replace
