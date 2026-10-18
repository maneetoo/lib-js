--!strict

--[=[
	@class ToFixedSizeInteger
	@private

	ECMA-262 §7.1.6 `ToFixedSizeInteger(int, signed, bitWidth)`.
	https://tc39.es/ecma262/#sec-tofixedsizeinteger

	Maps an integer into the fixed range of a `bitWidth`-bit integer. Unsigned
	values land in `[0, 2^bitWidth)`. Signed values land in
	`[-2^(bitWidth-1), 2^(bitWidth-1))`, the two's complement range.

	`ToInt8`, `ToUint8`, `ToInt16`, `ToUint16`, `ToInt32`, and `ToUint32` are all
	`ToIntegerOrInfinity` followed by this operation.
]=]

--[=[
	@within ToFixedSizeInteger
	@param int number -- an integer, `math.huge`, or `-math.huge`
	@param signed boolean -- `true` for a signed result, `false` for unsigned
	@param bitWidth number -- a positive integer, such as `8`, `16`, `32`
	@return number -- the fixed-size integer

	`±∞` gives `0`. Otherwise the result is `int` reduced modulo `2^bitWidth`.
	A signed result at or above `2^(bitWidth-1)` is shifted down by `2^bitWidth`.

	:::note
	`math.fmod` is used for the reduction, not `%`. `fmod` is exact for every
	float, including values above `2^53`, while `%` can lose precision there.
	:::

	:::caution
	`int` must already be an integer or infinity, as the output of
	`ToIntegerOrInfinity` is. A fraction is not truncated here.
	:::
]=]
const function ToFixedSizeInteger(int: number, signed: boolean, bitWidth: number): number
	if int == math.huge or int == -math.huge then
		return 0
	end
	const modulus = 2 ^ bitWidth
	local fixed = math.fmod(int, modulus)
	if fixed < 0 then
		fixed += modulus
	end
	if signed and fixed >= modulus / 2 then
		fixed -= modulus
	end
	return fixed
end

return ToFixedSizeInteger
