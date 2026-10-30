--!strict

--[=[
	@class __shared
	@private

	Internal machinery shared by the `uri` modules: the unreserved and
	reserved character sets, the percent-encoding engine, and the
	percent-decoding engine with its strict UTF-8 validation. Not part of
	the public API.

	:::note
	Keep helpers small. Logic used by a single method lives in that method's file.
	:::
]=]

const URIError = require("../Error").URIError

-- Percent-encodes one byte as `%XX` (uppercase hex, as JavaScript does).
const HEX = "0123456789ABCDEF"

--[=[
	@within __shared
	@private

	True if `byte` (an ASCII byte value) belongs to the unreserved set every
	encoder leaves alone: `A-Z a-z 0-9 - _ . ! ~ * ' ( )`.
]=]
const function isUnreserved(byte: number): boolean
	if byte >= 0x41 and byte <= 0x5A then -- A-Z
		return true
	end
	if byte >= 0x61 and byte <= 0x7A then -- a-z
		return true
	end
	if byte >= 0x30 and byte <= 0x39 then -- 0-9
		return true
	end
	return byte == 0x2D -- -
		or byte == 0x5F -- _
		or byte == 0x2E -- .
		or byte == 0x21 -- !
		or byte == 0x7E -- ~
		or byte == 0x2A -- *
		or byte == 0x27 -- '
		or byte == 0x28 -- (
		or byte == 0x29 -- )
end

--[=[
	@within __shared
	@private

	True if `byte` additionally belongs to the reserved set `encodeURI`
	leaves alone: `; / ? : @ & = + $ , #`.
]=]
const function isReserved(byte: number): boolean
	return byte == 0x3B -- ;
		or byte == 0x2F -- /
		or byte == 0x3F -- ?
		or byte == 0x3A -- :
		or byte == 0x40 -- @
		or byte == 0x26 -- &
		or byte == 0x3D -- =
		or byte == 0x2B -- +
		or byte == 0x24 -- $
		or byte == 0x2C -- ,
		or byte == 0x23 -- #
end

--[=[
	@within __shared
	@private

	Percent-encodes `text`, leaving alone the bytes `isKept` approves. Every
	other byte becomes `%XX` with uppercase hex digits.
]=]
const function encodeWith(text: string, isKept: (byte: number) -> boolean): string
	const parts: { string } = {}
	local count = 0
	local runStart = 1
	const length = #text
	for index = 1, length do
		const byte = string.byte(text, index) :: number
		if isKept(byte) then
			continue
		end
		if runStart < index then
			count += 1
			parts[count] = string.sub(text, runStart, index - 1)
		end
		count += 1
		parts[count] = "%" .. HEX:sub(byte // 16 + 1, byte // 16 + 1) .. HEX:sub(byte % 16 + 1, byte % 16 + 1)
		runStart = index + 1
	end
	if runStart <= length then
		count += 1
		parts[count] = string.sub(text, runStart, length)
	end
	return table.concat(parts)
end

--[=[
	@within __shared
	@private

	Parses the two hex digits after the `%` at `index` (1-based). Returns the
	byte value, or `nil` when the digits are not valid hex.
]=]
const function hexPair(text: string, index: number): number?
	const high, low = string.byte(text, index), string.byte(text, index + 1)
	if high == nil or low == nil then
		return nil
	end
	local highValue, lowValue
	if high >= 0x30 and high <= 0x39 then
		highValue = high - 0x30
	elseif high >= 0x41 and high <= 0x46 then
		highValue = high - 0x37
	elseif high >= 0x61 and high <= 0x66 then
		highValue = high - 0x57
	end
	if low >= 0x30 and low <= 0x39 then
		lowValue = low - 0x30
	elseif low >= 0x41 and low <= 0x46 then
		lowValue = low - 0x37
	elseif low >= 0x61 and low <= 0x66 then
		lowValue = low - 0x57
	end
	if highValue == nil or lowValue == nil then
		return nil
	end
	return highValue * 16 + lowValue
end

--[=[
	@within __shared
	@private

	Decodes the percent-sequences of `text`. When `keepReserved` is true,
	sequences decoding to a reserved byte are kept as-is (`%2F` stays `%2F`),
	which is `decodeURI`'s rule; `decodeURIComponent` passes `false`.

	Every decoded byte must form valid UTF-8 overall: continuation bytes must
	follow leads, sequences must not be overlong or surrogate or beyond
	U+10FFFF, exactly as JavaScript's decode rejects them. A violation throws
	a `URIError` ("URI malformed").
]=]
const function decodeWith(text: string, keepReserved: boolean): string
	const parts: { string }, length = {}, #text
	local count, runStart, index = 0, 1, 1

	while index <= length do
		const byte = string.byte(text, index) :: number
		if byte ~= 0x25 then -- not '%'
			index += 1
			continue
		end

		-- Collect the whole (possibly multi-byte) percent-sequence run.
		const sequence: { number } = {}
		local seqCount, scan = 0, index
		while scan <= length do
			if string.byte(text, scan) ~= 0x25 then
				break
			end
			const value = hexPair(text, scan + 1)
			if value == nil then
				error(URIError.new("URI malformed"), 3)
			end
			seqCount += 1
			sequence[seqCount] = value
			scan += 3
		end
		if seqCount == 0 then
			error(URIError.new("URI malformed"), 3)
		end

		-- A reserved byte never appears inside a multi-byte UTF-8 sequence,
		-- so this only applies to single-byte runs.
		if keepReserved and seqCount == 1 and isReserved(sequence[1]) then
			index = scan
			continue
		end

		-- Validate and decode the run as UTF-8, one character at a time.
		-- Each lead byte groups with the continuation bytes that follow it;
		-- an ASCII byte is a whole character on its own.
		if runStart < index then
			count += 1
			parts[count] = string.sub(text, runStart, index - 1)
		end
		local position = 1
		while position <= seqCount do
			const b = sequence[position]
			local expected: number
			local codePoint: number
			if b < 0x80 then
				expected = 0
				codePoint = b
			elseif b >= 0xC2 and b <= 0xDF then
				expected = 1
				codePoint = b - 0xC0
			elseif b >= 0xE0 and b <= 0xEF then
				expected = 2
				codePoint = b - 0xE0
			elseif b >= 0xF0 and b <= 0xF4 then
				expected = 3
				codePoint = b - 0xF0
			else
				error(URIError.new("URI malformed"), 3)
			end
			if position + expected > seqCount then
				error(URIError.new("URI malformed"), 3)
			end
			for offset = 1, expected do
				const continuation = sequence[position + offset]
				if continuation < 0x80 or continuation > 0xBF then
					error(URIError.new("URI malformed"), 3)
				end
				codePoint = codePoint * 0x40 + (continuation - 0x80)
			end
			if codePoint > 0x10FFFF or (codePoint >= 0xD800 and codePoint <= 0xDFFF) then
				error(URIError.new("URI malformed"), 3)
			end
			-- Overlong form: the sequence used more bytes than the code
			-- point needs.
			const used = expected + 1
			const minLength = if codePoint < 0x80
				then 1
				elseif codePoint < 0x800 then 2
				elseif codePoint < 0x10000 then 3
				else 4
			if used < minLength then
				error(URIError.new("URI malformed"), 3)
			end
			count += 1
			parts[count] = utf8.char(codePoint)
			position += used
		end
		runStart = scan
		index = scan
	end

	if runStart <= length then
		count += 1
		parts[count] = string.sub(text, runStart, length)
	end
	return table.concat(parts)
end

return table.freeze({
	isUnreserved = isUnreserved,
	isReserved = isReserved,
	encodeWith = encodeWith,
	decodeWith = decodeWith,
})
