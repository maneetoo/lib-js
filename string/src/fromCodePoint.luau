--!strict

--[=[
	@class fromCodePoint

	A Luau implementation of JavaScript's [`String.fromCodePoint()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/fromCodePoint).

	Builds a string from Unicode code points.
]=]

const Number = require "../Number"
const __utf8 = require "./__utf8"

--[=[
	@within fromCodePoint
	@param ... unknown -- code points, each an integer from `0` to `0x10FFFF`
	@return string -- the string built from the code points

	:::caution
	A value that is not an integer in range throws a `RangeError`, as in
	JavaScript.

	A surrogate code point (`0xD800..0xDFFF`) has no UTF-8 form, so it
	becomes U+FFFD. JavaScript would keep the lone surrogate.
	:::
]=]
const function fromCodePoint(...: unknown): string
	const count = select("#", ...)
	const codePoints: { number } = {}

	for index = 1, count do
		const value = select(index, ...)
		const numeric = Number.__toNumber(value)
		if numeric ~= numeric or numeric % 1 ~= 0 or numeric < 0 or numeric > 0x10FFFF then
			error(`Invalid code point {tostring(value)}`)
		end
		codePoints[index] = math.floor(numeric)
	end

	return __utf8.encode(codePoints, 1, count)
end

return fromCodePoint
