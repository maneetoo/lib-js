--!strict

--[=[
	@class log2

	A Luau implementation of JavaScript's
	[`Math.log2()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/log2).

	Luau's `math` library has no `log2`. This uses `math.log` with base `2`.
]=]

const Number = require("../Number")

--[=[
	@within log2
	@param x any -- the value whose base-2 logarithm to return
	@return number -- `log2(x)`
]=]
const function log2(x: any): number
	return math.log(Number(x), 2)
end

return log2
