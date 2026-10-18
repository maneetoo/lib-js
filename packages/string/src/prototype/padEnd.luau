--!strict

--[=[
	@class padEnd

	A Luau implementation of JavaScript's [`String.prototype.padEnd()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/padEnd).

	Pads the end of a string to a target length.
]=]

const ECMAScript = require "../../ECMAScript"
const __shared = require "../__shared"
const __toString = require "../__toString"
const __utf8 = require "../__utf8"

--[=[
	@within padEnd
	@param self unknown -- the string to pad
	@param maxLength unknown -- the target length in code points
	@param fillString unknown -- the text to repeat at the end (default `" "`)
	@return string -- the padded string, or `self` when it is already long enough

	The fill is cut short when it does not divide evenly into the gap.

	:::caution
	A result longer than the string length limit throws a `RangeError`.
	:::
]=]
const function padEnd(self: unknown, maxLength: unknown, fillString: unknown): string
	const s = __shared.thisString(self, "padEnd")
	const target = ECMAScript.ToLength(maxLength)
	const length = __utf8.length(s)
	if target <= length then
		return s
	end

	const fill = if fillString == nil then " " else __toString(fillString)
	const fillLength = __utf8.length(fill)
	if fillLength == 0 then
		return s
	end

	const gap = target - length
	__shared.checkStringLength(#s + gap * #fill)
	-- Whole copies of `fill` are repeated directly. A partial copy is sliced
	-- from `fill` alone, so the big repeated string is never sliced.
	const full = math.floor(gap / fillLength)
	const remainder = gap - full * fillLength
	const partial = if remainder > 0 then __utf8.sub(fill, 0, remainder) else ""
	return s .. string.rep(fill, full) .. partial
end

return padEnd
