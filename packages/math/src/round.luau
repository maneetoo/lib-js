--!strict

--[=[
	@class round

	A Luau implementation of JavaScript's
	[`Math.round()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/round).

	Luau's `math.round` differs here: it rounds ties away from zero, so
	`math.round(-2.5)` is `-3`. JavaScript rounds ties toward `+Infinity`, so
	`Math.round(-2.5)` is `-2`.
]=]

const Number = require "../Number"

--[=[
	@within round
	@param x any -- the value to round
	@return number -- `x` rounded to the nearest integer, with ties toward `+Infinity`

	:::note
	`round(-0.3)` is `-0`. A zero result from a negative input keeps its sign.
	:::
]=]
const function round(x: any): number
	const value: number = Number(x)
	if value ~= value or value == Number.POSITIVE_INFINITY or value == Number.NEGATIVE_INFINITY then
		return value
	end
	const floored: number = math.floor(value)
	-- `value - floored` is exact for every double, which the naive
	-- `floor(value + 0.5)` is not (`0.49999999999999994`).
	const result: number = if value - floored >= 0.5 then floored + 1 else floored
	if result == 0 and (value < 0 or 1 / value < 0) then
		return -0.0
	end
	return result
end

return round
