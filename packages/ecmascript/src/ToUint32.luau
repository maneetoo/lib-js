--!strict

--[=[
	@class ToUint32
	@private

	ECMA-262 §7.1.7 `ToUint32(argument)`.
	https://tc39.es/ecma262/#sec-touint32

	Returns the unsigned 32-bit integer in `[0, 2^32)`. `NaN`, `±Infinity`, and
	`±0` give `0`.
]=]

const ToIntegerOrInfinity = require("./ToIntegerOrInfinity")
const ToFixedSizeInteger = require("./ToFixedSizeInteger")

--[=[
	@within ToUint32
	@param value any
	@return number
]=]
const function ToUint32(value: any): number
	return ToFixedSizeInteger(ToIntegerOrInfinity(value), false, 32)
end

return ToUint32
