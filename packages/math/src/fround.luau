--!strict

--[=[
	@class fround

	A Luau implementation of JavaScript's
	[`Math.fround()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/fround).

	Luau's `math` library has no single-precision rounding. This uses a 4-byte
	`buffer` to round-trip the value.
]=]

const Number = require("../Number")

const scratch: buffer = buffer.create(4)

--[=[
	@within fround
	@param x any -- the value to round to single precision
	@return number -- the nearest IEEE 754 single-precision value to `x`, as a double

	Overflows to `±Infinity` past the single-precision range. Values too small
	for single precision become subnormal or zero.
]=]
const function fround(x: any): number
	buffer.writef32(scratch, 0, Number(x))
	return buffer.readf32(scratch, 0)
end

return fround
