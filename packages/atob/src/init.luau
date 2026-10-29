--!strict

--[=[
	@class atob

	A Luau implementation of the global
	[`atob()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/atob)
	base64 decoding function, as it exists in browsers and as a global in
	Node.js 16+.

	Decodes base64 back to a *binary string* (one character per decoded
	byte). Deliberately strict, unlike a forgiving byte-array decoder: any
	character outside the base64 alphabet, any whitespace, and malformed
	padding throw.

	```lua
	local atob = require(path.to.atob)

	print(atob("aGVsbG8=")) -- hello
	print(atob("Zm9vYg"))   -- foob (missing padding tolerated)
	```

	:::caution
	JavaScript throws an `InvalidCharacterError` `DOMException`. There is no
	`DOMException` in this library, so this function throws a plain `Error`
	with the same message ("is not correctly encoded") — the documented
	divergence.
	:::
]=]

const Error = require("../Error")

const BASE64_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- Map from ASCII code to 6-bit value, `nil` for non-alphabet bytes.
local DECODE_TABLE: { [number]: number } = {}
for index = 1, #BASE64_ALPHABET do
	DECODE_TABLE[string.byte(BASE64_ALPHABET, index)] = index - 1
end

--[=[
	@within atob
	@param data string -- base64 text
	@return string -- the decoded binary string

	Decodes base64. Strict, like the JS `atob`: only `A-Z a-z 0-9 + /` and
	`=` padding are accepted, and whitespace is *not* skipped. Missing
	padding is tolerated (forgiving, as the HTML spec's decoder is), but
	wrong-length padding, stray `=` in the middle, or a trailing group that
	would decode more bytes than it can hold throws.

	The result is a binary string: one character per decoded byte.
]=]
const function atob(data: string): string
	if type(data) ~= "string" then
		error(Error.new(`atob: argument must be a string, got {typeof(data)}`), 2)
	end

	const length = #data
	if length == 0 then
		return ""
	end

	-- Validate and strip trailing padding.
	local unpadded = length
	local padding = 0
	if data:sub(-1) == "=" then
		padding = 1
		unpadded = length - 1
		if data:sub(-2, -2) == "=" then
			padding = 2
			unpadded = length - 2
		end
	end

	-- HTML forgiving-base64 rules: with padding present the total length
	-- must be a multiple of 4 (only the tail may pad, with `==` after 2
	-- data characters or `=` after 3); without padding any data length
	-- except a remainder of 1 is accepted.
	if padding > 0 and length % 4 ~= 0 then
		error(Error.new("atob: the string to be decoded is not correctly encoded"), 2)
	end
	if unpadded % 4 == 1 then
		error(Error.new("atob: the string to be decoded is not correctly encoded"), 2)
	end

	-- Every unpadded character must be in the alphabet; padding must be
	-- only at the very end (already stripped), never in the middle.
	for index = 1, length do
		const byte = string.byte(data, index) :: number
		if index <= unpadded then
			if DECODE_TABLE[byte] == nil then
				error(Error.new("atob: the string to be decoded is not correctly encoded"), 2)
			end
		elseif byte ~= 0x3D then -- '='
			error(Error.new("atob: the string to be decoded is not correctly encoded"), 2)
		end
	end

	const parts: { string } = {}
	local count = 0
	local index = 1
	-- Full groups of four characters decode to three bytes.
	while index + 3 <= unpadded do
		local c1 = DECODE_TABLE[string.byte(data, index) :: number] :: number
		local c2 = DECODE_TABLE[string.byte(data, index + 1) :: number] :: number
		local c3 = DECODE_TABLE[string.byte(data, index + 2) :: number] :: number
		local c4 = DECODE_TABLE[string.byte(data, index + 3) :: number] :: number
		local combined = c1 * 0x40000 + c2 * 0x1000 + c3 * 0x40 + c4
		local b1 = combined // 0x10000
		local b2 = (combined // 0x100) % 0x100
		local b3 = combined % 0x100
		count += 1
		parts[count] = string.char(b1, b2, b3)
		index += 4
	end

	-- Tail: two characters decode one byte, three decode two.
	const remaining = unpadded - index + 1
	if remaining == 2 then
		local c1 = DECODE_TABLE[string.byte(data, index) :: number] :: number
		local c2 = DECODE_TABLE[string.byte(data, index + 1) :: number] :: number
		count += 1
		parts[count] = string.char(c1 * 4 + c2 // 16)
	elseif remaining == 3 then
		local c1 = DECODE_TABLE[string.byte(data, index) :: number] :: number
		local c2 = DECODE_TABLE[string.byte(data, index + 1) :: number] :: number
		local c3 = DECODE_TABLE[string.byte(data, index + 2) :: number] :: number
		count += 1
		parts[count] = string.char(c1 * 4 + c2 // 16, (c2 % 16) * 16 + c3 // 4)
	end

	return table.concat(parts)
end

return atob
