--!strict

--[=[
	@class codePointAt

	A Luau implementation of JavaScript's [`String.prototype.codePointAt()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/codePointAt).

	Returns the Unicode code point at an index.
]=]

const ECMAScript = require("../../ECMAScript")
const __shared = require("../__shared")
const __utf8 = require("../__utf8")

--[=[
	@within codePointAt
	@param self unknown -- the string to read from
	@param position unknown -- the code point index (default `0`)
	@return number? -- the code point, or `nil` when out of range

	Because this library indexes by code point, the result matches JavaScript
	for every character. Unlike `charCodeAt`, it does not return a surrogate
	for characters outside the Basic Multilingual Plane.
]=]
const function codePointAt(self: unknown, position: unknown): number?
	const s = __shared.thisString(self, "codePointAt")
	const index = ECMAScript.ToIntegerOrInfinity(position)
	if index < 0 then
		return nil
	end
	return __utf8.codeAt(s, index)
end

return codePointAt
