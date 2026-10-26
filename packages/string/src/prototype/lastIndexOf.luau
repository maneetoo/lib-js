--!strict

--[=[
	@class lastIndexOf

	A Luau implementation of JavaScript's [`String.prototype.lastIndexOf()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/lastIndexOf).

	Finds the last occurrence of a substring.
]=]

const Number = require("../../Number")
const ECMAScript = require("../../ECMAScript")
const __shared = require("../__shared")
const __utf8 = require("../__utf8")

--[=[
	@within lastIndexOf
	@param self unknown -- the string to search in
	@param search unknown -- the substring to look for
	@param position unknown -- the latest code point index a match may start at (default: the end)
	@return number -- the code point index of the last match, or `-1`

	A `position` of `NaN` (or `nil`) means no limit, as in JavaScript.
]=]
const function lastIndexOf(self: unknown, search: unknown, position: unknown): number
	const s = __shared.thisString(self, "lastIndexOf")
	const pattern = ECMAScript.ToString(search)
	const length = __utf8.length(s)

	-- A NaN position means "no limit", so NaN is checked before ToInteger,
	-- which would turn it into 0.
	local start: number
	const numeric = if position == nil then 0 / 0 else Number(position)
	if numeric ~= numeric then
		start = length
	else
		start = ECMAScript.ToIntegerOrInfinity(numeric)
	end

	return __utf8.rfind(s, pattern, __shared.clamp(start, 0, length))
end

return lastIndexOf
