--!strict

--[=[
	@class isWellFormed

	A Luau implementation of JavaScript's [`String.prototype.isWellFormed()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/isWellFormed).

	Checks whether the string contains any invalid UTF-8.
]=]

const __shared = require "../__shared"
const __utf8 = require "../__utf8"

--[=[
	@within isWellFormed
	@param self unknown -- the string to check
	@return boolean -- `true` if every byte belongs to a valid UTF-8 sequence

	Encoding and decoding a string gives back the same bytes exactly when it
	is well formed. Anything else was changed by the decoder.
]=]
const function isWellFormed(self: unknown): boolean
	const s = __shared.thisString(self, "isWellFormed")
	const codePoints = __utf8.decode(s)
	return __utf8.encode(codePoints, 1, #codePoints) == s
end

return isWellFormed
