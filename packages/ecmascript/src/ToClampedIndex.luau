--!strict

--[=[
	@class ToClampedIndex
	@private

	ECMA-262 `ToClampedIndex(value, length)`: converts a relative index to an
	absolute index clamped to `0 .. length`.
	https://tc39.es/ecma262/#sec-toclampedindex
]=]

const ToIntegerOrInfinity = require("./ToIntegerOrInfinity")

--[=[
	@within ToClampedIndex
	@param value any -- the relative index
	@param length number -- the length the index is relative to, a non-negative integer
	@return number -- an integer in `0 .. length`

	`ToClampedIndex(-1, 5)` gives `4`. `ToClampedIndex(10, 5)` gives `5`.
	`ToClampedIndex(-math.huge, 5)` gives `0`.
]=]
const function ToClampedIndex(value: any, length: number): number
	const relative = ToIntegerOrInfinity(value)
	if relative == -math.huge then
		return 0
	end
	if relative < 0 then
		return math.max(length + relative, 0)
	end
	return math.min(relative, length)
end

return ToClampedIndex
