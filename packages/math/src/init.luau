--!strict

--[=[
	@class Math

	A Luau port of JavaScript's
	[`Math`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math)
	namespace object: eight constants and the static functions for common
	mathematical operations.

	```lua
	local Math = require(path.to.Math)

	print(Math.max(1, 3, 2))        -- 3
	print(Math.round(-2.5))         -- -2
	print(Math.imul(0xffffffff, 5)) -- -5
	```

	:::note
	`Math` is not a constructor. It is a plain namespace table, and calling
	it is an error. Its `[Symbol.toStringTag]` is `"Math"`, so
	`Object.prototype.toString` reports `"[object Math]"`.
	:::

	:::note
	Every function coerces its arguments with `ToNumber`, as JavaScript does.
	So `Math.abs("-3")` is `3`, and `Math.abs()` is `NaN`. A `Symbol`
	argument throws a `TypeError`. BigInt is not supported.
	:::

	:::note
	Each function that Luau's `math` library lacks, or implements differently,
	lives in its own module next to this file (`acosh`, `round`, `pow`, ...).
	The rest wrap the matching `math` function after coercion. Constants live
	in `__staticProps`, as in `Number`.
	:::

	:::caution
	Results depend on the platform's floating-point math library, so the last
	bit of a transcendental function (`sin`, `exp`, `log`, ...) may differ
	between platforms. Those functions are not exact.
	:::

	:::note
	`random` uses Luau's `math.random`. It is not cryptographically secure.
	:::

	:::note
	The module table is frozen with `table.freeze`. No members can be added,
	removed, or reassigned.
	:::
]=]

const Symbol = require "./Symbol"
const Number = require "./Number"
const __staticProps = require "@self/__staticProps"

const acosh = require "@self/acosh"
const asinh = require "@self/asinh"
const atanh = require "@self/atanh"
const cbrt = require "@self/cbrt"
const clz32 = require "@self/clz32"
const expm1 = require "@self/expm1"
const fround = require "@self/fround"
const hypot = require "@self/hypot"
const imul = require "@self/imul"
const log1p = require "@self/log1p"
const log2 = require "@self/log2"
const max = require "@self/max"
const min = require "@self/min"
const pow = require "@self/pow"
const round = require "@self/round"
const sign = require "@self/sign"
const trunc = require "@self/trunc"

--[=[
	@within Math
	@param x any -- the value whose absolute value to return
	@return number -- `|x|`
]=]
const function abs(x: any): number
	return math.abs(Number(x))
end

--[=[
	@within Math
	@param x any -- the value whose arc cosine to return, in `[-1, 1]`
	@return number -- the arc cosine of `x`, in radians, or `NaN` if `x` is outside `[-1, 1]`
]=]
const function acos(x: any): number
	return math.acos(Number(x))
end

--[=[
	@within Math
	@param x any -- the value whose arc sine to return, in `[-1, 1]`
	@return number -- the arc sine of `x`, in radians, or `NaN` if `x` is outside `[-1, 1]`
]=]
const function asin(x: any): number
	return math.asin(Number(x))
end

--[=[
	@within Math
	@param x any -- the value whose arc tangent to return
	@return number -- the arc tangent of `x`, in radians, in `(-π/2, π/2)`
]=]
const function atan(x: any): number
	return math.atan(Number(x))
end

--[=[
	@within Math
	@param y any -- the y coordinate
	@param x any -- the x coordinate
	@return number -- the angle, in radians, from the positive x axis to the point `(x, y)`, in `[-π, π]`
]=]
const function atan2(y: any, x: any): number
	return math.atan2(Number(y), Number(x))
end

--[=[
	@within Math
	@param x any -- the value to round up
	@return number -- the smallest integer greater than or equal to `x`. `-0` stays `-0`.
]=]
const function ceil(x: any): number
	return math.ceil(Number(x))
end

--[=[
	@within Math
	@param x any -- the angle, in radians
	@return number -- the cosine of `x`
]=]
const function cos(x: any): number
	return math.cos(Number(x))
end

--[=[
	@within Math
	@param x any -- the value whose hyperbolic cosine to return
	@return number -- `cosh(x)`
]=]
const function cosh(x: any): number
	return math.cosh(Number(x))
end

--[=[
	@within Math
	@param x any -- the exponent
	@return number -- `e` raised to the power `x`
]=]
const function exp(x: any): number
	return math.exp(Number(x))
end

--[=[
	@within Math
	@param x any -- the value to round down
	@return number -- the largest integer less than or equal to `x`. `-0` stays `-0`.
]=]
const function floor(x: any): number
	return math.floor(Number(x))
end

--[=[
	@within Math
	@param x any -- the value whose natural logarithm to return
	@return number -- `ln(x)`. `NaN` for `x < 0`, and `-Infinity` for `x == 0`.
]=]
const function log(x: any): number
	return math.log(Number(x))
end

--[=[
	@within Math
	@param x any -- the value whose base-10 logarithm to return
	@return number -- `log10(x)`
]=]
const function log10(x: any): number
	return math.log10(Number(x))
end

--[=[
	@within Math
	@return number -- a pseudo-random number in `[0, 1)`
]=]
const function random(): number
	return math.random()
end

--[=[
	@within Math
	@param x any -- the value whose square root to return
	@return number -- `sqrt(x)`, or `NaN` if `x < 0`
]=]
const function sqrt(x: any): number
	return math.sqrt(Number(x))
end

--[=[
	@within Math
	@param x any -- the angle, in radians
	@return number -- the sine of `x`
]=]
const function sin(x: any): number
	return math.sin(Number(x))
end

--[=[
	@within Math
	@param x any -- the value whose hyperbolic sine to return
	@return number -- `sinh(x)`
]=]
const function sinh(x: any): number
	return math.sinh(Number(x))
end

--[=[
	@within Math
	@param x any -- the angle, in radians
	@return number -- the tangent of `x`
]=]
const function tan(x: any): number
	return math.tan(Number(x))
end

--[=[
	@within Math
	@param x any -- the value whose hyperbolic tangent to return
	@return number -- `tanh(x)`, in `[-1, 1]`
]=]
const function tanh(x: any): number
	return math.tanh(Number(x))
end

const Math = table.freeze {
	E = __staticProps.E,
	LN2 = __staticProps.LN2,
	LN10 = __staticProps.LN10,
	LOG2E = __staticProps.LOG2E,
	LOG10E = __staticProps.LOG10E,
	PI = __staticProps.PI,
	SQRT1_2 = __staticProps.SQRT1_2,
	SQRT2 = __staticProps.SQRT2,

	abs = abs,
	acos = acos,
	acosh = acosh,
	asin = asin,
	asinh = asinh,
	atan = atan,
	atanh = atanh,
	atan2 = atan2,
	cbrt = cbrt,
	ceil = ceil,
	clz32 = clz32,
	cos = cos,
	cosh = cosh,
	exp = exp,
	expm1 = expm1,
	floor = floor,
	fround = fround,
	hypot = hypot,
	imul = imul,
	log = log,
	log1p = log1p,
	log10 = log10,
	log2 = log2,
	max = max,
	min = min,
	pow = pow,
	random = random,
	round = round,
	sign = sign,
	sin = sin,
	sinh = sinh,
	sqrt = sqrt,
	tan = tan,
	tanh = tanh,
	trunc = trunc,

	[Symbol.toStringTag] = "Math",
}

return Math
