--!strict

--[=[
	@class trunc

	A Luau implementation of JavaScript's
	[`Math.trunc()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/trunc).

	Luau's `math` library has no `trunc`.
]=]

const Number = require("../Number")

--[=[
	@within trunc
	@param x any -- the value to truncate
	@return number -- `x` with its fractional part removed. `-0` stays `-0`.
]=]
const function trunc(x: any): number
	const value: number = Number(x)
	if value ~= value or value == Number.POSITIVE_INFINITY or value == Number.NEGATIVE_INFINITY then
		return value
	end
	if value < 0 then
		return math.ceil(value)
	end
	return math.floor(value)
end

return trunc
