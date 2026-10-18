--!strict

--[=[
	@class toWellFormed

	A Luau implementation of JavaScript's [`String.prototype.toWellFormed()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/toWellFormed).

	Replaces invalid UTF-8 with the replacement character.
]=]

const __shared = require "../__shared"
const __utf8 = require "../__utf8"

--[=[
	@within toWellFormed
	@param self unknown -- the string to repair
	@return string -- the string with every invalid byte replaced by U+FFFD

	A valid string is returned unchanged.
]=]
const function toWellFormed(self: unknown): string
	const codePoints = __utf8.decode(__shared.thisString(self, "toWellFormed"))
	return __utf8.encode(codePoints, 1, #codePoints)
end

return toWellFormed
