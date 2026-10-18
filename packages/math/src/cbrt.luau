--!strict

--[=[
	@class cbrt

	A Luau implementation of JavaScript's
	[`Math.cbrt()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/cbrt).

	Luau's `math` library has no `cbrt`.
]=]

const Number = require "../Number"

const TINY: number, HUGE_THRESHOLD: number = 2 ^ -600, 2 ^ 900
const UP: number, SMALL_STEP: number = 2 ^ 600, 2 ^ 200

--[=[
	@within cbrt
	@private
	One Newton step on `|a|^(1/3)`, for `a` in the range where `root^3` is safe.
]=]
const function refine(a: number): number
	local root: number = a ^ (1 / 3)
	if root ~= 0 then
		root = root - (root * root * root - a) / (3 * root * root)
	end
	return root
end

--[=[
	@within cbrt
	@param x any -- the value whose cube root to return
	@return number -- the real cube root of `x`

	Takes `|x|^(1/3)` and does one Newton step, which corrects the rounding
	error of `^`. For example, `cbrt(27)` is exactly `3`.
]=]
const function cbrt(x: any): number
	const value: number = Number(x)
	if value ~= value or value == 0 or value == Number.POSITIVE_INFINITY or value == Number.NEGATIVE_INFINITY then
		return value
	end
	const a: number = math.abs(value)
	-- The Newton step computes `root^3`. That underflows for subnormal `a`
	-- and overflows for huge `a`. Scaling `a` by a power of 8 (an exact
	-- power of 2, so the scaling is exact) keeps the step in range.
	local root: number
	if a < TINY then
		root = refine(a * UP) / SMALL_STEP
	elseif a > HUGE_THRESHOLD then
		root = refine(a / UP) * SMALL_STEP
	else
		root = refine(a)
	end
	return if value < 0 then -root else root
end

return cbrt
