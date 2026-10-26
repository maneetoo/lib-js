--!strict

--[=[
	@class fromCharCode

	A Luau implementation of JavaScript's [`String.fromCharCode()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/fromCharCode).

	Builds a string from UTF-16 code units.
]=]

const ECMAScript = require("../ECMAScript")
const __utf8 = require("./__utf8")

--[=[
	@within fromCharCode
	@param ... unknown -- code units; each is reduced to `0 .. 65535`
	@return string -- the string built from the code units

	Each argument is converted with `ToUint16`, as in JavaScript. A high
	surrogate followed by a low surrogate is combined into one code point.

	:::caution
	A lone surrogate has no UTF-8 form, so it becomes U+FFFD.
	:::
]=]
const function fromCharCode(...: unknown): string
	const count = select("#", ...)
	const codePoints: { number } = {}
	local index, length = 1, 0

	while index <= count do
		const unit = ECMAScript.ToUint16((select(index, ...)))
		const following = if index < count then ECMAScript.ToUint16((select(index + 1, ...))) else -1

		length += 1
		if unit >= 0xD800 and unit <= 0xDBFF and following >= 0xDC00 and following <= 0xDFFF then
			codePoints[length] = 0x10000 + (unit - 0xD800) * 0x400 + (following - 0xDC00)
			index += 2
		else
			codePoints[length] = unit
			index += 1
		end
	end

	return __utf8.encode(codePoints, 1, length)
end

return fromCharCode
