--!strict

--[=[
	@class SameValueZero
	@private

	ECMA-262 §7.2.11 `SameValueZero(x, y)`.
	https://tc39.es/ecma262/#sec-samevaluezero

	Like `SameValue`, but `+0` and `-0` are equal. `NaN` equals `NaN`.
	This is the comparison that `Array.prototype.includes` uses.
]=]

--[=[
	@within SameValueZero
	@param x any
	@param y any
	@return boolean
]=]
const function sameValueZero(x: any, y: any): boolean
	if type(x) == "number" and type(y) == "number" then
		if x ~= x then
			return y ~= y
		end
		return x == y
	end
	return rawequal(x, y)
end

return sameValueZero
