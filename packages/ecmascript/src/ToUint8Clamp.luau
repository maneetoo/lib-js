--!strict

--[=[
	@class ToUint8Clamp
	@private

	ECMA-262 §7.1.12 `ToUint8Clamp(argument)`.
	https://tc39.es/ecma262/#sec-touint8clamp

	Converts to an integer from 0 to 255. Values outside that range are clamped.
	Halfway values round to the nearest even integer.
]=]

const Number = require "../Number"

--[=[
	@within ToUint8Clamp
	@param argument any
	@return number -- an integer in `0 .. 255`

	`ToUint8Clamp(2.5)` gives `2`. `ToUint8Clamp(3.5)` gives `4`.
	`ToUint8Clamp(300)` gives `255`. `ToUint8Clamp(0/0)` gives `0`.
]=]
const function ToUint8Clamp(argument: any): number
	const n = Number(argument)
	if n ~= n or n <= 0 then
		return 0
	end
	if n >= 255 then
		return 255
	end
	const f = math.floor(n)
	if f + 0.5 < n then
		return f + 1
	end
	if n < f + 0.5 then
		return f
	end
	if f % 2 == 1 then
		return f + 1
	end
	return f
end

return ToUint8Clamp
