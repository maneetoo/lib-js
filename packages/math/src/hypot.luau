--!strict

--[=[
	@class hypot

	A Luau implementation of JavaScript's
	[`Math.hypot()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/hypot).

	Luau's `math` library has no `hypot`.
]=]

const Number = require("../Number")

--[=[
	@within hypot
	@param ... any -- the values to square, sum, and take the root of
	@return number -- `sqrt(x1^2 + x2^2 + ...)`, or `0` with no arguments

	:::note
	The result is `Infinity` if any argument is `±Infinity`, even if another
	argument is `NaN`. Otherwise it is `NaN` if any argument is `NaN`. The
	computation scales by the largest magnitude, so it does not overflow when
	the squares would.
	:::
]=]
const function hypot(...: any): number
	const count: number = select("#", ...)
	local hasInfinity: boolean, hasNaN: boolean, largest: number, values: { number } =
		false, false, 0, table.create(count)
	for index = 1, count do
		const value = math.abs(Number((select(index, ...))))
		values[index] = value
		if value == Number.POSITIVE_INFINITY then
			hasInfinity = true
		elseif value ~= value then
			hasNaN = true
		elseif value > largest then
			largest = value
		end
	end
	if hasInfinity then
		return Number.POSITIVE_INFINITY
	end
	if hasNaN then
		return Number.NaN
	end
	if largest == 0 then
		return 0
	end
	local sum: number = 0
	for index = 1, count do
		const scaled = values[index] / largest
		sum += scaled * scaled
	end
	return largest * math.sqrt(sum)
end

return hypot
