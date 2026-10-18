--!strict

--[=[
	@class __utf8
	@private

	Code-point access to Luau's UTF-8 strings. Luau counts bytes, while
	`String` counts code points (see `String`'s class docs).

	Pure-ASCII strings use byte operations directly, because there bytes and
	code points are the same. Any other string is decoded into an array of
	code points.

	:::note
	Each invalid byte decodes to U+FFFD, the replacement character. Decoding
	rejects overlong forms, surrogates (U+D800..U+DFFF) and values above
	U+10FFFF, as the WHATWG UTF-8 decoder does.
	:::
]=]

const REPLACEMENT = 0xFFFD

--[=[
	@private
	True if `s` contains only ASCII bytes.
]=]
const function isAscii(s: string): boolean
	return string.find(s, "[\128-\255]") == nil
end

--[=[
	@private
	Returns the byte at `index` if it lies in `[low, high]`, otherwise `nil`.
]=]
const function byteIn(s: string, index: number, low: number, high: number): number?
	const byte = string.byte(s, index)
	if byte ~= nil and byte >= low and byte <= high then
		return byte
	end
	return nil
end

--[=[
	@private
	Decodes `s` into an array of code points, one per character. Invalid
	sequences give one U+FFFD per invalid byte.
]=]
const function decode(s: string): { number }
	const codePoints: { number } = {}
	const length = #s
	local count = 0
	local index = 1

	while index <= length do
		const lead = string.byte(s, index) :: number
		local codePoint = REPLACEMENT
		local width = 1

		if lead < 0x80 then
			codePoint = lead
		elseif lead >= 0xC2 and lead <= 0xDF then
			const second = byteIn(s, index + 1, 0x80, 0xBF)
			if second then
				codePoint = (lead - 0xC0) * 0x40 + (second - 0x80)
				width = 2
			end
		elseif lead >= 0xE0 and lead <= 0xEF then
			const secondLow = if lead == 0xE0 then 0xA0 else 0x80
			const secondHigh = if lead == 0xED then 0x9F else 0xBF
			const second = byteIn(s, index + 1, secondLow, secondHigh)
			const third = if second then byteIn(s, index + 2, 0x80, 0xBF) else nil
			if second and third then
				codePoint = (lead - 0xE0) * 0x1000 + (second - 0x80) * 0x40 + (third - 0x80)
				width = 3
			end
		elseif lead >= 0xF0 and lead <= 0xF4 then
			const secondLow = if lead == 0xF0 then 0x90 else 0x80
			const secondHigh = if lead == 0xF4 then 0x8F else 0xBF
			const second = byteIn(s, index + 1, secondLow, secondHigh)
			const third = if second then byteIn(s, index + 2, 0x80, 0xBF) else nil
			const fourth = if third then byteIn(s, index + 3, 0x80, 0xBF) else nil
			if second and third and fourth then
				codePoint = (lead - 0xF0) * 0x40000 + (second - 0x80) * 0x1000 + (third - 0x80) * 0x40 + (fourth - 0x80)
				width = 4
			end
		end

		count += 1
		codePoints[count] = codePoint
		index += width
	end

	return codePoints
end

--[=[
	@private
	Decodes the single character that starts at byte `index` (1-based). Returns
	its code point and its width in bytes. An invalid sequence gives U+FFFD with
	width `1`.
]=]
const function step(s: string, index: number): (number, number)
	const lead = string.byte(s, index) :: number
	if lead < 0x80 then
		return lead, 1
	elseif lead >= 0xC2 and lead <= 0xDF then
		const second = byteIn(s, index + 1, 0x80, 0xBF)
		if second then
			return (lead - 0xC0) * 0x40 + (second - 0x80), 2
		end
	elseif lead >= 0xE0 and lead <= 0xEF then
		const secondLow = if lead == 0xE0 then 0xA0 else 0x80
		const secondHigh = if lead == 0xED then 0x9F else 0xBF
		const second = byteIn(s, index + 1, secondLow, secondHigh)
		const third = if second then byteIn(s, index + 2, 0x80, 0xBF) else nil
		if second and third then
			return (lead - 0xE0) * 0x1000 + (second - 0x80) * 0x40 + (third - 0x80), 3
		end
	elseif lead >= 0xF0 and lead <= 0xF4 then
		const secondLow = if lead == 0xF0 then 0x90 else 0x80
		const secondHigh = if lead == 0xF4 then 0x8F else 0xBF
		const second = byteIn(s, index + 1, secondLow, secondHigh)
		const third = if second then byteIn(s, index + 2, 0x80, 0xBF) else nil
		const fourth = if third then byteIn(s, index + 3, 0x80, 0xBF) else nil
		if second and third and fourth then
			return (lead - 0xF0) * 0x40000 + (second - 0x80) * 0x1000 + (third - 0x80) * 0x40 + (fourth - 0x80), 4
		end
	end
	return REPLACEMENT, 1
end

--[=[
	@private
	UTF-8 for one code point. A surrogate has no UTF-8 form, so it becomes
	U+FFFD.
]=]
const function encodeOne(codePoint: number): string
	if codePoint >= 0xD800 and codePoint <= 0xDFFF then
		return utf8.char(REPLACEMENT)
	end
	return utf8.char(codePoint)
end

--[=[
	@private
	Encodes `codePoints[from..to]` (1-based, inclusive) as one string.
]=]
const function encode(codePoints: { number }, from: number, to: number): string
	const parts: { string } = {}
	local count = 0
	for index = from, to do
		count += 1
		parts[count] = encodeOne(codePoints[index])
	end
	return table.concat(parts)
end

--[=[
	@private
	Number of code points in `s`. Walks the bytes with `step`, without building
	an array.
]=]
const function length(s: string): number
	if isAscii(s) then
		return #s
	end
	local count = 0
	local index = 1
	const byteLength = #s
	while index <= byteLength do
		local _, width = step(s, index)
		count += 1
		index += width
	end
	return count
end

--[=[
	@private
	Substring from code point `from` (inclusive) to `to` (exclusive), both
	0-based. The caller keeps `0 <= from <= to <= length(s)`.

	Valid runs are sliced straight from the bytes. Each invalid byte becomes
	U+FFFD, the same result a full decode and re-encode would give, with no
	array allocated.
]=]
const function sub(s: string, from: number, to: number): string
	if to <= from then
		return ""
	end
	if isAscii(s) then
		return string.sub(s, from + 1, to)
	end
	const byteLength = #s
	local index = 1
	local position = 0
	-- Skip the first `from` code points.
	while position < from and index <= byteLength do
		local _, width = step(s, index)
		index += width
		position += 1
	end
	local runStart = index
	local parts: { string } = {}
	local count = 0
	while position < to and index <= byteLength do
		local codePoint, width = step(s, index)
		if width == 1 and codePoint == REPLACEMENT then
			if runStart < index then
				count += 1
				parts[count] = string.sub(s, runStart, index - 1)
			end
			count += 1
			parts[count] = utf8.char(REPLACEMENT)
			runStart = index + 1
		end
		index += width
		position += 1
	end
	if runStart < index then
		count += 1
		parts[count] = string.sub(s, runStart, index - 1)
	end
	return table.concat(parts)
end

--[=[
	@private
	Code point at index `index` (0-based), or `nil` when out of range. Walks
	the bytes with `step`.
]=]
const function codeAt(s: string, index: number): number?
	if isAscii(s) then
		return string.byte(s, index + 1)
	end
	local position = 0
	local byteIndex = 1
	const byteLength = #s
	while byteIndex <= byteLength do
		local codePoint, width = step(s, byteIndex)
		if position == index then
			return codePoint
		end
		byteIndex += width
		position += 1
	end
	return nil
end

--[=[
	@private
	Naive forward search of `needle` in `hay`, starting at 0-based `from`.
	Returns the 0-based index, or -1.
]=]
const function searchForward(hay: { number }, needle: { number }, from: number): number
	const hayLength, needleLength = #hay, #needle
	for start = from + 1, hayLength - needleLength + 1 do
		local matched = true
		for offset = 1, needleLength do
			if hay[start + offset - 1] ~= needle[offset] then
				matched = false
				break
			end
		end
		if matched then
			return start - 1
		end
	end
	return -1
end

--[=[
	@private
	Index of the first occurrence of `search` at or after code point `from`,
	or -1. `from` must satisfy `0 <= from <= length(s)`.
]=]
const function find(s: string, search: string, from: number): number
	if isAscii(s) and isAscii(search) then
		const position = string.find(s, search, from + 1, true)
		if position then
			return position - 1
		end
		return -1
	end
	return searchForward(decode(s), decode(search), from)
end

--[=[
	@private
	Index of the last occurrence of `search` starting at or before code point
	`from`, or -1.
]=]
const function rfind(s: string, search: string, from: number): number
	if isAscii(s) and isAscii(search) then
		-- Plain `string.find` calls step forward. The last match at or before
		-- `from` wins. The loop stops at the first match beyond `from`.
		local last = -1
		local position = string.find(s, search, 1, true)
		while position and position - 1 <= from do
			last = position - 1
			position = string.find(s, search, position + 1, true)
		end
		return last
	end
	const hay, needle = decode(s), decode(search)
	const needleLength = #needle
	const highest = math.min(from, #hay - needleLength)
	for index = highest, 0, -1 do
		local matched = true
		for offset = 1, needleLength do
			if hay[index + offset] ~= needle[offset] then
				matched = false
				break
			end
		end
		if matched then
			return index
		end
	end
	return -1
end

--[=[
	@private
	Simple case mapping for one code point. It covers ASCII, Latin-1, Greek
	and Cyrillic only. Special casing such as `ß` to `SS` is not applied.
]=]
const function mapCase(codePoint: number, upper: boolean): number
	if upper then
		if codePoint >= 0x61 and codePoint <= 0x7A then
			return codePoint - 0x20
		end
		if codePoint >= 0xE0 and codePoint <= 0xFE and codePoint ~= 0xF7 then
			return codePoint - 0x20
		end
		if codePoint == 0x3C2 then
			return 0x3A3
		end
		if codePoint >= 0x3B1 and codePoint <= 0x3C9 then
			return codePoint - 0x20
		end
		if codePoint >= 0x430 and codePoint <= 0x44F then
			return codePoint - 0x20
		end
		if codePoint >= 0x450 and codePoint <= 0x45F then
			return codePoint - 0x50
		end
	else
		if codePoint >= 0x41 and codePoint <= 0x5A then
			return codePoint + 0x20
		end
		if codePoint >= 0xC0 and codePoint <= 0xDE and codePoint ~= 0xD7 then
			return codePoint + 0x20
		end
		if codePoint >= 0x391 and codePoint <= 0x3A9 and codePoint ~= 0x3A2 then
			return codePoint + 0x20
		end
		if codePoint >= 0x410 and codePoint <= 0x42F then
			return codePoint + 0x20
		end
		if codePoint >= 0x400 and codePoint <= 0x40F then
			return codePoint + 0x50
		end
	end
	return codePoint
end

--[=[
	@private
	Maps every character of `s` to upper or lower case.
]=]
const function changeCase(s: string, upper: boolean): string
	if isAscii(s) then
		return if upper then string.upper(s) else string.lower(s)
	end
	const codePoints = decode(s)
	for index, codePoint in codePoints do
		codePoints[index] = mapCase(codePoint, upper)
	end
	return encode(codePoints, 1, #codePoints)
end

return table.freeze {
	isAscii = isAscii,
	decode = decode,
	encode = encode,
	length = length,
	sub = sub,
	codeAt = codeAt,
	find = find,
	rfind = rfind,
	changeCase = changeCase,
}
