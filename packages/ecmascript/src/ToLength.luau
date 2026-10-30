--!strict

--[=[
	@class ToLength
	@private

	ECMA-262 §7.1.20 `ToLength(argument)`.
	https://tc39.es/ecma262/#sec-tolength

	Clamps `ToIntegerOrInfinity(value)` to `[0, 2^53 - 1]`.
]=]

const Number = require("../Number")
const ToIntegerOrInfinity = require("./ToIntegerOrInfinity")

--[=[
	@within ToLength
	@param value any
	@return number
]=]
const function ToLength(value: any): number
	const len: number = ToIntegerOrInfinity(value)
	if len <= 0 then
		return 0
	end
	return math.min(len, Number.MAX_SAFE_INTEGER)
end

return ToLength
