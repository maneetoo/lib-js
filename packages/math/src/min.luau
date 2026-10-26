--!strict

--[=[
	@class min

	A Luau implementation of JavaScript's
	[`Math.min()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/min).

	Luau's `math.min` differs here: it ignores `NaN` in some positions, and it
	does not treat `-0` as smaller than `+0`.
]=]

const Number = require("../Number")

--[=[
	@within min
	@param ... any -- the values to compare
	@return number -- the smallest argument, or `Infinity` with no arguments. `NaN` if any argument is `NaN`.

	`-0` counts as smaller than `+0`. Every argument is coerced, even after a
	`NaN` is seen.
]=]
const function min(...: any): number
	const count = select("#", ...)
	local result, sawNaN = Number.POSITIVE_INFINITY, false
	for index = 1, count do
		const value = Number((select(index, ...)))
		if value ~= value then
			sawNaN = true
		elseif value < result or (value == 0 and result == 0 and 1 / value < 0) then
			result = value
		end
	end
	if sawNaN then
		return Number.NaN
	end
	return result
end

return min
