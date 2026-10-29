--!strict

--[=[
	@class atob-btoa

	Luau implementations of the global
	[`atob()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/atob) and
	[`btoa()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/btoa)
	base64 functions, as they exist in browsers and as globals in Node.js 16+.

	`btoa` encodes a *binary string* (every character a byte value 0–255) to
	base64; `atob` decodes base64 back to one. They are deliberately strict,
	unlike a forgiving byte-array decoder: any character outside the base64
	alphabet, any whitespace, and malformed padding throw.

	```lua
	local atob = require(path.to["atob-btoa"]).atob

	local atob = require(path.to.atobBtoa).atob
	local btoa = require(path.to.atobBtoa).btoa

	print(btoa("hello"))  -- aGVsbG8=
	print(atob("aGVsbG8=")) -- hello
	```

	:::caution
	JavaScript throws an `InvalidCharacterError` `DOMException`. There is no
	`DOMException` in this library, so both functions throw a plain `Error`
	with the same messages ("contains characters outside of the Latin1 range",
	"is not correctly encoded") — the documented divergence.
	:::

	:::caution
	For multi-byte text, JavaScript's own workaround is to UTF-8-encode first
	and build a binary string from the bytes. The same applies here: `btoa`
	on a string with non-Latin1 characters throws, exactly as in JS.
	:::
]=]

const Error = require("./Error")

const BASE64_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- Map from ASCII code to 6-bit value, `nil` for non-alphabet bytes.
local DECODE_TABLE: { [number]: number } = {}
for index = 1, #BASE64_ALPHABET do
	DECODE_TABLE[string.byte(BASE64_ALPHABET, index)] = index - 1
end

--[=[
	@within atob-btoa
	@param data string -- a Latin-1 binary string (every character a byte)
	@return string -- the base64 encoding, with `=` padding

	Encodes `data` to base64. Every character must be a byte value 0–255:
	a string holding a character beyond Latin-1 throws (the same characters
	the JS `btoa` rejects), because base64 encodes bytes, not code points.

	Groups of three bytes become four alphabet characters; the final group is
	padded with `=` to a multiple of four.
]=]
local function btoa(data: string): string
	if type(data) ~= "string" then
		error(Error.new(`btoa: argument must be a string, got {typeof(data)}`), 2)
	end

	-- Latin-1 check. Luau strings are byte arrays, so what JS calls one
	-- "character" only exists when the bytes form valid UTF-8: a multi-byte
	-- sequence decodes to one code point, and a code point above 0xFF is
	-- outside Latin-1 (exactly what JS btoa rejects). Lone high bytes that
	-- do not form valid UTF-8 are raw Latin-1 bytes and legal here.
	local byteIndex = 1
	const dataLength = #data
	while byteIndex <= dataLength do
		const lead = string.byte(data, byteIndex) :: number
		if lead < 0x80 then
			byteIndex += 1
			continue
		end
		-- Measure the UTF-8 sequence width from the lead byte.
		local width
		if lead >= 0xC2 and lead <= 0xDF then
			width = 2
		elseif lead >= 0xE0 and lead <= 0xEF then
			width = 3
		elseif lead >= 0xF0 and lead <= 0xF4 then
			width = 4
		else
			-- Invalid lead byte (or a bare continuation byte): treat the
			-- rest as raw Latin-1 bytes.
			break
		end
		if byteIndex + width - 1 > dataLength then
			break -- truncated sequence: raw bytes from here on
		end
		local valid = true
		for offset = 1, width - 1 do
			const b = string.byte(data, byteIndex + offset) :: number
			if b < 0x80 or b > 0xBF then
				valid = false
				break
			end
		end
		if not valid then
			break -- not a real sequence: raw Latin-1 bytes
		end
		const codePoint = utf8.codepoint(string.sub(data, byteIndex, byteIndex + width - 1))
		if codePoint ~= nil and codePoint > 0xFF then
			error(Error.new("btoa: the string to be encoded contains characters outside of the Latin1 range"), 2)
		end
		byteIndex += width
	end

	const parts: { string } = {}
	local count = 0
	const length = #data
	local index = 1
	while index + 2 <= length do
		local b1, b2, b3 = string.byte(data, index, index + 2)
		local combined = (b1 :: number) * 0x10000 + (b2 :: number) * 0x100 + (b3 :: number)
		local c1 = combined // 0x40000
		local c2 = (combined // 0x1000) % 64
		local c3 = (combined // 0x40) % 64
		local c4 = combined % 64
		count += 1
		parts[count] = string.char(
			string.byte(BASE64_ALPHABET, c1 + 1),
			string.byte(BASE64_ALPHABET, c2 + 1),
			string.byte(BASE64_ALPHABET, c3 + 1),
			string.byte(BASE64_ALPHABET, c4 + 1)
		)
		index += 3
	end

	const remaining = length - index + 1
	if remaining == 1 then
		const byte = string.byte(data, index) :: number
		count += 1
		parts[count] = string.char(
			string.byte(BASE64_ALPHABET, byte // 4 + 1),
			string.byte(BASE64_ALPHABET, (byte % 4) * 16 + 1),
			0x3D,
			0x3D -- '=='
		)
	elseif remaining == 2 then
		local b1, b2 = string.byte(data, index, index + 1)
		const combined = (b1 :: number) * 0x100 + (b2 :: number)
		count += 1
		parts[count] = string.char(
			string.byte(BASE64_ALPHABET, combined // 0x400 + 1),
			string.byte(BASE64_ALPHABET, (combined // 0x10) % 64 + 1),
			string.byte(BASE64_ALPHABET, (combined % 0x10) * 4 + 1),
			0x3D -- '='
		)
	end

	return table.concat(parts)
end

local function atob(data: string): string
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

return table.freeze({
	atob = atob,
	btoa = btoa,
})
