--!strict

--[=[
	@class max

	A Luau implementation of JavaScript's
	[`Math.max()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/max).

	Luau's `math.max` differs here: it ignores `NaN` in some positions, and it
	does not treat `+0` as larger than `-0`.
]=]

const Number = require("../Number")

--[=[
	@within max
	@param ... any -- the values to compare
	@return number -- the largest argument, or `-Infinity` with no arguments. `NaN` if any argument is `NaN`.

	`+0` counts as larger than `-0`. Every argument is coerced, even after a
	`NaN` is seen, so the coercion order matches JavaScript.
]=]
const function max(...: any): number
	const count = select("#", ...)
	local result, sawNaN = Number.NEGATIVE_INFINITY, false
	for index = 1, count do
		const value = Number((select(index, ...)))
		if value ~= value then
			sawNaN = true
		elseif value > result or (value == 0 and result == 0 and 1 / result < 0) then
			result = value
		end
	end
	if sawNaN then
		return Number.NaN
	end
	return result
end

return max
