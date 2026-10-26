--!strict

--[=[
	@class sign

	A Luau implementation of JavaScript's
	[`Math.sign()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/sign).

	Luau's `math.sign` differs here: it returns `0` for `NaN`, where JavaScript
	returns `NaN`.
]=]

const Number = require("../Number")

--[=[
	@within sign
	@param x any -- the value whose sign to return
	@return number -- `1`, `-1`, `0`, `-0`, or `NaN`
]=]
const function sign(x: any): number
	const value = Number(x)
	if value ~= value or value == 0 then
		return value
	end
	return if value > 0 then 1 else -1
end

return sign
