--!strict

--[=[
	@class SameValue
	@private

	ECMA-262 §7.2.10 `SameValue(x, y)`.
	https://tc39.es/ecma262/#sec-samevalue

	Like strict equality, but `NaN` equals `NaN`. Zero and negative zero are
	different. Luau's `==` treats them as equal, so the sign is detected
	through `1 / x`, which is `inf` for `+0` and `-inf` for `-0`.

	:::note
	`sameValue` on tables and functions is reference equality, which matches
	JavaScript object identity.
	:::
]=]

--[=[
	@within SameValue
	@param x any
	@param y any
	@return boolean
]=]
const function sameValue(x: any, y: any): boolean
	if type(x) == "number" and type(y) == "number" then
		if x ~= x then
			return y ~= y
		end
		if x == 0 and y == 0 then
			return (1 / x) == (1 / y)
		end
		return x == y
	end
	return rawequal(x, y)
end

return sameValue
