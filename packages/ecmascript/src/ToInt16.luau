--!strict

--[=[
	@class ToInt16
	@private

	ECMA-262 §7.1.9 `ToInt16(argument)`.
	https://tc39.es/ecma262/#sec-toint16

	Returns the signed 16-bit integer for `value`. `NaN`, `±Infinity`, and `±0`
	give `0`. Otherwise the value is truncated, reduced modulo 2^16, and mapped
	into `[-2^15, 2^15)`.
]=]

const ToIntegerOrInfinity = require("./ToIntegerOrInfinity")
const ToFixedSizeInteger = require("./ToFixedSizeInteger")

--[=[
	@within ToInt16
	@param value any
	@return number
]=]
const function ToInt16(value: any): number
	return ToFixedSizeInteger(ToIntegerOrInfinity(value), true, 16)
end

return ToInt16
