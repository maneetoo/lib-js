--!strict

--[=[
	@class uri

	Luau implementations of JavaScript's global URI functions:
	[`encodeURI()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURI),
	[`encodeURIComponent()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent),
	[`decodeURI()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURI)
	and
	[`decodeURIComponent()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURIComponent).

	All four share one UTF-8 percent-encoding algorithm and differ only in
	which characters they leave unescaped:

	- `encodeURI` keeps the unreserved set plus the reserved set
	  (`; / ? : @ & = + $ , #`), so a whole URI's structure survives.
	- `encodeURIComponent` keeps only the unreserved set
	  (`A-Z a-z 0-9 - _ . ! ~ * ' ( )`), escaping everything a component must
	  not carry.
	- `decodeURI` decodes percent-sequences except those that decode to
	  reserved characters.
	- `decodeURIComponent` decodes every percent-sequence.

	```lua
	local uri = require(path.to.uri)

	print(uri.encodeURI("https://x/a b?q=é"))      -- https://x/a%20b?q=%C3%A9
	print(uri.encodeURIComponent("Jack & Jill"))   -- Jack%20%26%20Jill
	print(uri.decodeURIComponent("Jack%20%26%20Jill")) -- Jack & Jill
	```

	:::caution
	JavaScript operates on UTF-16 code units and throws a `URIError` when
	encoding a lone surrogate. Luau strings are byte sequences that cannot
	contain invalid UTF-8 by construction, so that error cannot happen here;
	an invalid byte is percent-encoded as-is.
	:::
]=]

const TypeError = require("./Error").TypeError
const URIError = require("./Error").URIError

--[=[
	@within uri
	@prop encodeURI (uri: string) -> string
	@prop encodeURIComponent (component: string) -> string
	@prop decodeURI (uri: string) -> string
	@prop decodeURIComponent (component: string) -> string

	The four functions, exactly as in JavaScript. Non-string inputs are
	converted with the library's `ToString` rules where that matters; each
	function's own documentation below covers its behaviour.
]=]

-- Percent-encodes one byte as `%XX` (uppercase hex, as JavaScript does).
const HEX = "0123456789ABCDEF"

--[=[
	@within uri
	@private
	True if `byte` (an ASCII byte value) belongs to the unreserved set every
	encoder leaves alone: `A-Z a-z 0-9 - _ . ! ~ * ' ( )`.
]=]
local function isUnreserved(byte: number): boolean
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
	@within uri
	@private
	True if `byte` additionally belongs to the reserved set `encodeURI`
	leaves alone: `; / ? : @ & = + $ , #`.
]=]
local function isReserved(byte: number): boolean
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
	@within uri
	@private
	Percent-encodes `text`, leaving alone the bytes `isKept` approves. Every
	other byte becomes `%XX` with uppercase hex digits.
]=]
local function encodeWith(text: string, isKept: (byte: number) -> boolean): string
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
	@within uri
	@private
	Parses the two hex digits after the `%` at `index` (1-based). Returns the
	byte value, or `nil` when the digits are not valid hex.
]=]
local function hexPair(text: string, index: number): number?
	local high = string.byte(text, index)
	local low = string.byte(text, index + 1)
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
	@within uri
	@private
	Decodes the percent-sequences of `text`. When `keepReserved` is true,
	sequences decoding to a reserved byte are kept as-is (`%2F` stays `%2F`),
	which is `decodeURI`'s rule; `decodeURIComponent` passes `false`.

	Every decoded byte must form valid UTF-8 overall: continuation bytes must
	follow leads, sequences must not be overlong or surrogate or beyond
	U+10FFFF, exactly as JavaScript's decode rejects them. A violation throws
	a `URIError` ("URI malformed").
]=]
local function decodeWith(text: string, keepReserved: boolean): string
	const parts: { string } = {}
	local count = 0
	local runStart = 1
	const length = #text
	local index = 1

	while index <= length do
		const byte = string.byte(text, index) :: number
		if byte ~= 0x25 then -- not '%'
			index += 1
			continue
		end

		-- Collect the whole (possibly multi-byte) percent-sequence run.
		const sequence: { number } = {}
		local seqCount = 0
		local scan = index
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

--[=[
	@within uri
	@param uri string -- a complete URI
	@return string -- the URI with unsafe characters percent-encoded

	Encodes a complete URI: every byte not in the unreserved set
	(`A-Z a-z 0-9 - _ . ! ~ * ' ( )`) or the reserved set
	(`; / ? : @ & = + $ , #`) becomes `%XX`. The URI's structure characters
	survive untouched.
]=]
const function encodeURI(uri: string): string
	if type(uri) ~= "string" then
		error(TypeError.new("uri.encodeURI: argument must be a string"), 2)
	end
	return encodeWith(uri, function(byte: number): boolean
		return isUnreserved(byte) or isReserved(byte)
	end)
end

--[=[
	@within uri
	@param component string -- a single URI component
	@return string -- the component with everything structural escaped

	Encodes a URI component: every byte not in the unreserved set
	(`A-Z a-z 0-9 - _ . ! ~ * ' ( )`) becomes `%XX`. Reserved characters
	(`? & = /` ...) are escaped too, so the result is safe to embed as one
	Component of a larger URI.
]=]
const function encodeURIComponent(component: string): string
	if type(component) ~= "string" then
		error(TypeError.new("uri.encodeURIComponent: argument must be a string"), 2)
	end
	return encodeWith(component, isUnreserved)
end

--[=[
	@within uri
	@param uri string -- an encoded URI
	@return string -- the URI with decodable sequences decoded

	Decodes percent-sequences that do not stand for reserved characters:
	`%20` becomes a space, but `%2F` stays `%2F`, so an encoded `/` cannot
	quietly change the URI's structure. Throws a `URIError` on malformed
	sequences (bad hex, incomplete `%XX`, invalid UTF-8).
]=]
const function decodeURI(uri: string): string
	if type(uri) ~= "string" then
		error(TypeError.new("uri.decodeURI: argument must be a string"), 2)
	end
	return decodeWith(uri, true)
end

--[=[
	@within uri
	@param component string -- an encoded URI component
	@return string -- the component with every sequence decoded

	Decodes every percent-sequence, including those of reserved characters
	(`%2F` becomes `/`). Throws a `URIError` on malformed sequences.
]=]
const function decodeURIComponent(component: string): string
	if type(component) ~= "string" then
		error(TypeError.new("uri.decodeURIComponent: argument must be a string"), 2)
	end
	return decodeWith(component, false)
end

return table.freeze({
	encodeURI = encodeURI,
	encodeURIComponent = encodeURIComponent,
	decodeURI = decodeURI,
	decodeURIComponent = decodeURIComponent,
})
