--!strict

--[=[
	@class clz32

	A Luau implementation of JavaScript's
	[`Math.clz32()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/clz32).

	Luau's `math` library has no `clz32`.
]=]

const ECMAScript = require("../ECMAScript")

--[=[
	@within clz32
	@param x any -- the value whose leading zeros to count
	@return number -- the count of leading zero bits in `ToUint32(x)`, in `[0, 32]`
]=]
const function clz32(x: any): number
	const n = ECMAScript.ToUint32(x)
	if n == 0 then
		return 32
	end
	local count: number, value: number = 0, n
	while value < 2147483648 do
		count += 1
		value *= 2
	end
	return count
end

return clz32
