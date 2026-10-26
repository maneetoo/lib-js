--!strict

--[=[
	@class parse

	A Luau implementation of JavaScript's
	[`JSON.parse()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/parse).

	Parses a JSON text (ECMA-262 §25.5.1) and returns the Luau value it describes.
	An optional `reviver` is applied to every value after parsing.

	:::caution
	Luau has one `nil`, which stands for both JavaScript's `undefined` and `null`
	(see `requireObjectCoercible`). So the JSON `null` parses to `nil`. A `null`
	inside an array is a hole, and `stringify` writes it back as `null` when a
	later element keeps the array's length. A trailing `null` is lost, so
	`[1,null]` gives a one-element table. A property whose value is `null` is
	simply absent.
	:::

	:::caution
	`{}` and `[]` both parse to an empty table. An empty table is an array to
	`isArray`, so `stringify` writes it back as `[]`.
	:::

	:::note
	A string is UTF-8. A `\uXXXX` escape gives its code point as UTF-8. An
	unpaired surrogate is kept as its three-byte (WTF-8) form, which `stringify`
	writes back as the same escape.
	:::
]=]

const Array = require("../Array")
const ECMAScript = require("../ECMAScript")
const String = require("../String")
const Symbol = require("../Symbol")
const SyntaxError = require("../Error").SyntaxError
const TypeError = require("../Error").TypeError

type Cursor = {
	text: string,
	pos: number,
}

const function fail(cursor: Cursor): ()
	if cursor.pos > #cursor.text then
		error(SyntaxError.new("Unexpected end of JSON input"), 3)
	end
	const character: string = cursor.text:sub(cursor.pos, cursor.pos)
	error(SyntaxError.new(`Unexpected token '{character}' in JSON at position {cursor.pos - 1}`), 3)
end

const function skipWhitespace(cursor: Cursor)
	while true do
		const byte: number = cursor.text:byte(cursor.pos)
		-- space, tab, line feed, carriage return
		if byte == 32 or byte == 9 or byte == 10 or byte == 13 then
			cursor.pos += 1
		else
			return
		end
	end
end

const function isDigit(byte: number?): boolean
	return byte ~= nil and byte >= 48 and byte <= 57
end

const function isHexDigit(byte: number?): boolean
	return byte ~= nil and ((byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 70) or (byte >= 97 and byte <= 102))
end

-- Reads the four hex digits after `\u`, at `cursor.pos`, and advances past them.
const function readHex4(cursor: Cursor): number
	local value: number = 0
	for _ = 1, 4 do
		const byte: number = cursor.text:byte(cursor.pos)
		if not isHexDigit(byte) then
			error(SyntaxError.new(`Bad Unicode escape in JSON at position {cursor.pos - 1}`), 3)
		end
		value = value * 16 + tonumber(string.char(byte :: number), 16) :: number
		cursor.pos += 1
	end
	return value
end

-- Encodes one code point. Surrogates get the three-byte (WTF-8) form, which
-- `utf8.char` does not accept.
const function encodeCodePoint(code: number): string
	if code >= 0xD800 and code <= 0xDFFF then
		return string.char(0xE0 + math.floor(code / 4096), 0x80 + (math.floor(code / 64) % 64), 0x80 + (code % 64))
	end
	return utf8.char(code)
end

const function parseString(cursor: Cursor): string
	cursor.pos += 1 -- opening quote
	const parts: { string } = {}
	while true do
		const byte: number = cursor.text:byte(cursor.pos)
		if byte == nil then
			error(SyntaxError.new(`Unterminated string in JSON at position {cursor.pos - 1}`), 3)
		end
		if byte == 34 then -- closing quote
			cursor.pos += 1
			break
		end
		if byte == 92 then -- backslash
			const escape: string = cursor.text:sub(cursor.pos + 1, cursor.pos + 1)
			cursor.pos += 2
			if escape == '"' then
				table.insert(parts, '"')
			elseif escape == "\\" then
				table.insert(parts, "\\")
			elseif escape == "/" then
				table.insert(parts, "/")
			elseif escape == "b" then
				table.insert(parts, "\b")
			elseif escape == "f" then
				table.insert(parts, "\f")
			elseif escape == "n" then
				table.insert(parts, "\n")
			elseif escape == "r" then
				table.insert(parts, "\r")
			elseif escape == "t" then
				table.insert(parts, "\t")
			elseif escape == "u" then
				local code = readHex4(cursor)
				-- A high surrogate followed by `\u` and a low surrogate is one code point.
				if code >= 0xD800 and code <= 0xDBFF and cursor.text:sub(cursor.pos, cursor.pos + 1) == "\\u" then
					const savedPos: number = cursor.pos
					cursor.pos += 2
					const low: number = readHex4(cursor)
					if low >= 0xDC00 and low <= 0xDFFF then
						code = 0x10000 + (code - 0xD800) * 1024 + (low - 0xDC00)
					else
						cursor.pos = savedPos
					end
				end
				table.insert(parts, encodeCodePoint(code))
			else
				cursor.pos -= 1
				error(SyntaxError.new(`Bad escaped character in JSON at position {cursor.pos - 1}`), 2)
			end
		elseif byte < 32 then
			error(SyntaxError.new(`Bad control character in string literal in JSON at position {cursor.pos - 1}`), 2)
		else
			-- Copy the run of ordinary bytes up to the next quote, backslash, or control.
			const stop: number = cursor.text:find('["\\%c]', cursor.pos) or (#cursor.text + 1)
			table.insert(parts, cursor.text:sub(cursor.pos, stop - 1))
			cursor.pos = stop
		end
	end
	return table.concat(parts)
end

const function parseNumber(cursor: Cursor): number
	const start: number, text: string = cursor.pos, cursor.text
	if text:byte(cursor.pos) == 45 then -- minus
		cursor.pos += 1
	end
	if text:byte(cursor.pos) == 48 then -- leading zero: no more integer digits
		cursor.pos += 1
	elseif isDigit(text:byte(cursor.pos)) then
		while isDigit(text:byte(cursor.pos)) do
			cursor.pos += 1
		end
	else
		fail(cursor)
	end
	if text:byte(cursor.pos) == 46 then -- fraction
		cursor.pos += 1
		if not isDigit(text:byte(cursor.pos)) then
			fail(cursor)
		end
		while isDigit(text:byte(cursor.pos)) do
			cursor.pos += 1
		end
	end
	const exponentMark: number = text:byte(cursor.pos)
	if exponentMark == 101 or exponentMark == 69 then -- e or E
		cursor.pos += 1
		const sign = text:byte(cursor.pos)
		if sign == 43 or sign == 45 then
			cursor.pos += 1
		end
		if not isDigit(text:byte(cursor.pos)) then
			fail(cursor)
		end
		while isDigit(text:byte(cursor.pos)) do
			cursor.pos += 1
		end
	end
	-- `tonumber` rounds correctly and gives `-0` for "-0", as JSON requires.
	return tonumber(text:sub(start, cursor.pos - 1)) :: number
end

const function expectWord(cursor: Cursor, word: string)
	for index = 1, #word do
		if cursor.text:byte(cursor.pos) ~= word:byte(index) then
			fail(cursor)
		end
		cursor.pos += 1
	end
end

local parseValue

const function parseArray(cursor: Cursor): { any }
	cursor.pos += 1 -- opening bracket
	const result: { any } = {}
	skipWhitespace(cursor)
	if cursor.text:byte(cursor.pos) == 93 then -- closing bracket
		cursor.pos += 1
		return result
	end
	local count: number = 0
	while true do
		count += 1
		result[count] = parseValue(cursor)
		skipWhitespace(cursor)
		const byte: number = cursor.text:byte(cursor.pos)
		if byte == 44 then -- comma
			cursor.pos += 1
		elseif byte == 93 then
			cursor.pos += 1
			return result
		else
			fail(cursor)
		end
	end
end

const function parseObject(cursor: Cursor): { [string]: any }
	cursor.pos += 1 -- opening brace
	const result: { [string]: any } = {}
	skipWhitespace(cursor)
	if cursor.text:byte(cursor.pos) == 125 then -- closing brace
		cursor.pos += 1
		return result
	end
	while true do
		skipWhitespace(cursor)
		if cursor.text:byte(cursor.pos) ~= 34 then
			fail(cursor)
		end
		const key: string = parseString(cursor)
		skipWhitespace(cursor)
		if cursor.text:byte(cursor.pos) ~= 58 then -- colon
			fail(cursor)
		end
		cursor.pos += 1
		result[key] = parseValue(cursor)
		skipWhitespace(cursor)
		const byte: number = cursor.text:byte(cursor.pos)
		if byte == 44 then
			cursor.pos += 1
		elseif byte == 125 then
			cursor.pos += 1
			return result
		else
			fail(cursor)
		end
	end
end

parseValue = function(cursor: Cursor): any
	skipWhitespace(cursor)
	const byte: number = cursor.text:byte(cursor.pos)
	if byte == 123 then -- {
		return parseObject(cursor)
	elseif byte == 91 then -- [
		return parseArray(cursor)
	elseif byte == 34 then -- "
		return parseString(cursor)
	elseif byte == 116 then -- t
		expectWord(cursor, "true")
		return true
	elseif byte == 102 then -- f
		expectWord(cursor, "false")
		return false
	elseif byte == 110 then -- n
		expectWord(cursor, "null")
		return nil
	elseif byte == 45 or isDigit(byte) then
		return parseNumber(cursor)
	end
	fail(cursor)
	return nil
end

--[=[
	@within parse
	@private
	Applies `reviver` to `holder[rawKey]` and then to its children, depth first,
	as ECMA-262 §25.5.1.1 `InternalizeJSONProperty` does. A `nil` result removes
	the value.
]=]
const function walk(holder: { [any]: any }, rawKey: any, jsKey: string, reviver: (string, any) -> any?): any?
	const value = holder[rawKey]
	if type(value) == "table" then
		if Array.isArray(value) then
			for index = 1, #value do
				value[index] = walk(value, index, tostring(index - 1), reviver)
			end
		else
			const keys: { string } = {}
			for key in pairs(value) do
				if type(key) == "string" then
					table.insert(keys, key)
				end
			end
			for _, key in keys do
				value[key] = walk(value, key, key, reviver)
			end
		end
	end
	return reviver(jsKey, value)
end

--[=[
	@within parse
	@param text unknown -- the JSON text. Coerced to a string with `ToString`, so a non-string is parsed as its text.
	@param reviver ((key: string, value: any) -> any?)? -- optional. Called for each value, children first. Its return value replaces the value. `nil` removes it.
	@return any -- the parsed value

	Throws a `SyntaxError` if `text` is not valid JSON. The message gives the
	0-based position of the first bad character.

	:::note
	`reviver` is called as `reviver(key, value)`. Keys are strings, and array
	indices are the strings `"0"`, `"1"`, and so on, as in JavaScript. There is
	no `this`, so the holder is not passed.
	:::
]=]
const function parse(text: unknown?, reviver: unknown?): any
	if Symbol.isSymbol(text) then
		error(TypeError.new("Cannot convert a Symbol value to a string"), 2)
	end
	const cursor: Cursor = { text = String(text), pos = 1 }
	const value = parseValue(cursor)
	skipWhitespace(cursor)
	if cursor.pos <= #cursor.text then
		fail(cursor)
	end

	if ECMAScript.IsCallable(reviver) then
		const root: { [any]: any } = { [""] = value }
		return walk(root, "", "", reviver :: any)
	end
	return value
end

return parse
