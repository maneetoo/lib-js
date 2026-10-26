--!strict

--[=[
	@class ToInt8
	@private

	ECMA-262 §7.1.11 `ToInt8(argument)`.
	https://tc39.es/ecma262/#sec-toint8

	Returns the signed 8-bit integer for `value`. `NaN`, `±Infinity`, and `±0`
	give `0`. Otherwise the value is truncated, reduced modulo 2^8, and mapped
	into `[-2^7, 2^7)`.
]=]

const ToIntegerOrInfinity = require("./ToIntegerOrInfinity")
const ToFixedSizeInteger = require("./ToFixedSizeInteger")

--[=[
	@within ToInt8
	@param value any
	@return number
]=]
const function ToInt8(value: any): number
	return ToFixedSizeInteger(ToIntegerOrInfinity(value), true, 8)
end

return ToInt8
