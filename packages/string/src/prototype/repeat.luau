--!strict

--[=[
	@class repeat

	A Luau implementation of JavaScript's [`String.prototype.repeat()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/repeat).

	Returns the string repeated a number of times. The name is a Luau
	keyword, so call it as `String.prototype["repeat"](s, n)`.
]=]

const ECMAScript = require "../../ECMAScript"
const Number = require "../../Number"
const __shared = require "../__shared"

--[=[
	@within repeat
	@param self unknown -- the string to repeat
	@param count unknown -- how many copies; an integer from `0` upward
	@return string -- the repeated string

	:::caution
	A negative count, or an infinite one, throws a `RangeError`, as in
	JavaScript. So does a result longer than the string length limit.
	:::
]=]
const function repeatString(self: unknown, count: unknown): string
	const s = __shared.thisString(self, "repeat")
	const times = ECMAScript.ToIntegerOrInfinity(count)
	if times < 0 or times == Number.MAX_VALUE then
		error(`Invalid count value: {tostring(count)}`)
	end
	if times == 0 or s == "" then
		return ""
	end
	__shared.checkStringLength(#s * times)
	return string.rep(s, times)
end

return repeatString
