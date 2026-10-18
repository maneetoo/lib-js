--!strict

--[=[
	@class ToInt32
	@private

	ECMA-262 §7.1.6 `ToInt32(argument)`.
	https://tc39.es/ecma262/#sec-toint32

	Returns the signed 32-bit integer for `value`. `NaN`, `±Infinity`, and `±0`
	give `0`. Otherwise the value is truncated, reduced modulo 2^32, and mapped
	into `[-2^31, 2^31)`.
]=]

const ToIntegerOrInfinity = require "./ToIntegerOrInfinity"
const ToFixedSizeInteger = require "./ToFixedSizeInteger"

--[=[
	@within ToInt32
	@param value any
	@return number
]=]
const function ToInt32(value: any): number
	return ToFixedSizeInteger(ToIntegerOrInfinity(value), true, 32)
end

return ToInt32
