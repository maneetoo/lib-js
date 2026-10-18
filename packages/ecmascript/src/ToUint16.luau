--!strict

--[=[
	@class ToUint16
	@private

	ECMA-262 §7.1.10 `ToUint16(argument)`.
	https://tc39.es/ecma262/#sec-touint16

	Returns the unsigned 16-bit integer in `[0, 2^16)`. `NaN`, `±Infinity`, and
	`±0` give `0`.
]=]

const ToIntegerOrInfinity = require "./ToIntegerOrInfinity"
const ToFixedSizeInteger = require "./ToFixedSizeInteger"

--[=[
	@within ToUint16
	@param value any
	@return number
]=]
const function ToUint16(value: any): number
	return ToFixedSizeInteger(ToIntegerOrInfinity(value), false, 16)
end

return ToUint16
