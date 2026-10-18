--!strict

--[=[
	@class imul

	A Luau implementation of JavaScript's
	[`Math.imul()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/imul).

	Luau's `math` library has no `imul`.
]=]

const ECMAScript = require "../ECMAScript"

const TWO_TO_32 = 4294967296

--[=[
	@within imul
	@param a any -- the first factor
	@param b any -- the second factor
	@return number -- `a * b` as a signed 32-bit integer

	Both operands go through `ToUint32`. The product's low 32 bits are the same
	whichever way the operands are read. `b` is split into 16-bit halves, so each
	partial product stays below `2^48`, which a double holds exactly.
]=]
const function imul(a: any, b: any): number
	const ua: number, ub: number = ECMAScript.ToUint32(a), ECMAScript.ToUint32(b)
	const low: number = ub % 65536
	const high: number = (ub - low) / 65536
	const product: number = (ua * low + (ua * high % 65536) * 65536) % TWO_TO_32
	if product >= 2147483648 then
		return product - TWO_TO_32
	end
	return product
end

return imul
