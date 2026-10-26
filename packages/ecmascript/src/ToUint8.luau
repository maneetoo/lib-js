--!strict

--[=[
	@class ToUint8
	@private

	ECMA-262 §7.1.12 `ToUint8(argument)`.
	https://tc39.es/ecma262/#sec-touint8

	Returns the unsigned 8-bit integer in `[0, 2^8)`. `NaN`, `±Infinity`, and
	`±0` give `0`.
]=]

const ToIntegerOrInfinity = require("./ToIntegerOrInfinity")
const ToFixedSizeInteger = require("./ToFixedSizeInteger")

--[=[
	@within ToUint8
	@param value any
	@return number
]=]
const function ToUint8(value: any): number
	return ToFixedSizeInteger(ToIntegerOrInfinity(value), false, 8)
end

return ToUint8
