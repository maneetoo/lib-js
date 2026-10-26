--!strict

--[=[
	@class charCodeAt

	A Luau implementation of JavaScript's [`String.prototype.charCodeAt()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/charCodeAt).

	Returns the numeric value of the character at an index.
]=]

const ECMAScript = require("../../ECMAScript")
const __shared = require("../__shared")
const __utf8 = require("../__utf8")

--[=[
	@within charCodeAt
	@param self unknown -- the string to read from
	@param position unknown -- the code point index (default `0`)
	@return number -- the code point at that index, or `NaN` when out of range

	:::caution
	JavaScript returns a UTF-16 code unit here. This returns the full code
	point, which is the same for characters in the Basic Multilingual Plane.
	For characters outside it, the value differs from the surrogate that
	JavaScript would return.
	:::
]=]
const function charCodeAt(self: unknown, position: unknown): number
	const s = __shared.thisString(self, "charCodeAt")
	const index = ECMAScript.ToIntegerOrInfinity(position)
	if index < 0 then
		return 0 / 0
	end
	return __utf8.codeAt(s, index) or 0 / 0
end

return charCodeAt
