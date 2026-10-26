--!strict

--[=[
	@class ToIntegerOrInfinity
	@private

	ECMA-262 §7.1.5 `ToIntegerOrInfinity(argument)`.
	https://tc39.es/ecma262/#sec-tointegerorinfinity

	Converts with `Number`. `NaN` and `±0` give `0`. Infinities are returned
	as they are. Anything else is truncated toward zero.
]=]

const Number = require("../Number")

--[=[
	@within ToIntegerOrInfinity
	@param value any
	@return number
]=]
const function ToIntegerOrInfinity(value: any): number
	const number: number = Number(value)
	if number ~= number or number == 0 then
		return 0
	end
	if number == math.huge or number == -math.huge then
		return number
	end
	return if number < 0 then math.ceil(number) else math.floor(number)
end

return ToIntegerOrInfinity
