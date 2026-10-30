--!strict

--[=[
	@class btoa

	A Luau implementation of the global
	[`btoa()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/btoa)
	base64 encoding function, as it exists in browsers and as a global in
	Node.js 16+.

	Encodes a *binary string* (every character a byte value 0–255) to
	base64. Deliberately strict, unlike a forgiving byte-array encoder: the
	Latin-1 range is the whole input space, exactly as JavaScript defines it.

	```lua
	local btoa = require(path.to.btoa)

	print(btoa("hello")) -- aGVsbG8=
	print(btoa("caf\xe9")) -- Y2Fm6Q== (é is a Latin-1 byte, legal)
	```

	:::caution
	JavaScript throws an `InvalidCharacterError` `DOMException`. There is no
	`DOMException` in this library, so this function throws a plain `Error`
	with the same message ("contains characters outside of the Latin1
	range") — the documented divergence.
	:::

	:::caution
	For multi-byte text, JavaScript's own workaround is to UTF-8-encode
	first and build a binary string from the bytes. The same applies here:
	`btoa` on a string with a character beyond Latin-1 throws, exactly as
	JS does.
	:::
]=]

const Error = require("../Error")

const BASE64_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

--[=[
	@within btoa
	@param data string -- a Latin-1 binary string (every character a byte)
	@return string -- the base64 encoding, with `=` padding

	Encodes `data` to base64. Every character must be a byte value 0–255:
	a string holding a character beyond Latin-1 throws (the same characters
	the JS `btoa` rejects), because base64 encodes bytes, not code points.

	Groups of three bytes become four alphabet characters; the final group
	is padded with `=` to a multiple of four.
]=]
const function btoa(data: string): string
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

	const parts: { string }, length: number = {}, #data
	local count, index = 0, 1
	while index + 2 <= length do
		const b1, b2, b3 = string.byte(data, index, index + 2)
		const combined = (b1 :: number) * 0x10000 + (b2 :: number) * 0x100 + (b3 :: number)
		const c1 = combined // 0x40000
		const c2 = (combined // 0x1000) % 64
		const c3 = (combined // 0x40) % 64
		const c4 = combined % 64
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
		const b1, b2 = string.byte(data, index, index + 1)
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

return btoa
