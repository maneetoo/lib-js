--!strict

--[=[
	@class stringify

	A Luau implementation of JavaScript's
	[`JSON.stringify()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify).

	Serializes a value to JSON text (ECMA-262 §25.5.2). An optional `replacer`
	filters or changes values, and an optional `space` sets the indentation.

	:::caution
	Luau has one `nil`, which stands for both `undefined` and `null`. So `nil`
	is treated as `undefined`: it is left out of an object, written as `null`
	in an array, and gives `nil` at the top level.
	:::

	:::caution
	A table has no length for its `nil` holes, so an array is found from its
	keys. `[null, null, 3]` parsed from JSON is a table with only `[3] = 3`,
	and it does not look like an array (at least half of the slots up to 3
	must be filled). It serializes as `{"3":3}`, not `[null,null,3]`. `[1, null,
	3]` does round-trip, because it has two filled slots out of three.
	:::

	:::caution
	An empty table is an array to `isArray`, so `{}` serializes as `[]`. The
	built-in collections (`Map`, `Set`, `WeakMap`, `WeakSet`, `WeakRef`) and the
	namespace objects (`Math`, `JSON`) serialize as `{}`, as in JavaScript,
	where their properties are not enumerable. A plain table that sets
	`[Symbol.toStringTag]` to one of those names is treated the same way.
	:::

	:::caution
	Object keys are written in this order: integer-like keys ascending, then
	other keys sorted by string. JavaScript uses insertion order, which Luau's
	`next` does not keep, so the output is deterministic but may differ from a
	JavaScript engine's. The `replacer` property list fixes the order.
	:::

	:::caution
	Table keys, function keys, and `Symbol` keys are left out of an object.
	:::

	:::note
	A raw JSON object from `JSON.rawJSON` is written as its text, unchanged.
	:::

	:::note
	Numbers are formatted by `Number.prototype.toString`, which gives the
	shortest round-trip text, as JavaScript does. `NaN` and the infinities
	become `null`.
	:::

	:::note
	`toJSON` is looked up with `value.toJSON`. It is called as
	`value:toJSON(key)`, with `value` as `self`. The `replacer` is called as
	`replacer(key, value)`. There is no `this`, so the holder is not passed.
	:::
]=]

const Array = require "../Array"
const ECMAScript = require "../ECMAScript"
const Number = require "../Number"
const Symbol = require "../Symbol"
const TypeError = require "../Error" .TypeError
const __raw = require "./__raw"

const BUILTIN_TAGS: { [string]: boolean } = {
	Map = true,
	Set = true,
	WeakMap = true,
	WeakSet = true,
	WeakRef = true,
	Math = true,
	JSON = true,
}

const ESCAPES: { [string]: string } = {
	['"'] = '\\"',
	["\\"] = "\\\\",
	["\b"] = "\\b",
	["\f"] = "\\f",
	["\n"] = "\\n",
	["\r"] = "\\r",
	["\t"] = "\\t",
}

--[=[
	@within stringify
	@private
	Gives the surrogate code point (`U+D800..U+DFFF`) of a three-byte UTF-8
	sequence `ED xx yy`. `continuation` is the two bytes `xx yy`.
]=]
const function surrogateOf(continuation: string): number
	return 0xD000 + ((continuation:byte(1) :: number) % 64) * 64 + ((continuation:byte(2) :: number) % 64)
end

--[=[
	@within stringify
	@private
	Replaces each byte that is not part of a valid UTF-8 sequence with U+FFFD,
	as JavaScript does when it encodes a string. A surrogate written in WTF-8
	(`ED A0..BF xx`) is valid here, so `quote` can still see and escape it. A
	malformed sequence becomes one U+FFFD, as in WHATWG's decoder.
]=]
const function replaceInvalidUtf8(text: string): string
	if not text:find("[\128-\255]") then
		return text
	end
	const parts: { string } = {}
	const length = #text
	local index = 1
	while index <= length do
		const lead = text:byte(index) :: number
		local size = 0
		local low, high = 0x80, 0xBF
		if lead < 0x80 then
			size = 1
		elseif lead >= 0xC2 and lead <= 0xDF then
			size = 2
		elseif lead >= 0xE0 and lead <= 0xEF then
			size = 3
			if lead == 0xE0 then
				low = 0xA0
			end
		elseif lead >= 0xF0 and lead <= 0xF4 then
			size = 4
			if lead == 0xF0 then
				low = 0x90
			elseif lead == 0xF4 then
				high = 0x8F
			end
		end
		if size == 1 then
			table.insert(parts, text:sub(index, index))
			index += 1
		else
			-- Count the bytes that continue a valid sequence.
			local consumed = if size == 0 then 0 else 1
			while consumed < size and index + consumed <= length do
				const byte = text:byte(index + consumed) :: number
				const allowed = if consumed == 1 then (byte >= low and byte <= high) else (byte >= 0x80 and byte <= 0xBF)
				if not allowed then
					break
				end
				consumed += 1
			end
			if size > 0 and consumed == size then
				table.insert(parts, text:sub(index, index + size - 1))
			else
				table.insert(parts, "\239\191\189") -- U+FFFD
			end
			index += math.max(consumed, 1)
		end
	end
	return table.concat(parts)
end

--[=[
	@within stringify
	@private
	Quotes `text` as a JSON string. Pairs of surrogates become one character,
	lone surrogates become `\uXXXX`, and control characters are escaped.
]=]
const function quote(text: string): string
	-- A high surrogate followed by a low one is one astral character.
	local result = replaceInvalidUtf8(text):gsub(
		"\237([\160-\175][\128-\191])\237([\176-\191][\128-\191])",
		function(high: string, low: string): string
			const highCode = surrogateOf(high)
			const lowCode = surrogateOf(low)
			return utf8.char(0x10000 + (highCode - 0xD800) * 1024 + (lowCode - 0xDC00))
		end :: any
	)
	-- Escape quotes, backslashes, and control characters. Do this before the
	-- surrogate step below, which inserts backslashes of its own.
	result = result:gsub("[%c\"\\]", function(character: string): string
		const escape = ESCAPES[character]
		if escape then
			return escape
		end
		if character:byte() == 127 then
			return character
		end
		return string.format("\\u%04x", character:byte())
	end)
	-- Any surrogate left over is unpaired, so it is escaped.
	result = result:gsub("\237([\160-\191][\128-\191])", function(unit: string): string
		return string.format("\\u%04x", surrogateOf(unit))
	end)
	return '"' .. result .. '"'
end

--[=[
	@within stringify
	@private
	Formats a finite or non-finite number. `NaN` and the infinities become `null`.
]=]
const function formatNumber(value: number): string
	if value ~= value or value == math.huge or value == -math.huge then
		return "null"
	end
	return Number.prototype.toString(value)
end

--[=[
	@within stringify
	@private
	Whether `value` is one of the built-in objects that serialize as `{}`.
]=]
const function isOpaqueBuiltin(value: { [any]: any }): boolean
	const tag = value[Symbol.toStringTag]
	return type(tag) == "string" and BUILTIN_TAGS[tag] == true
end

--[=[
	@within stringify
	@private
	The length of `value` when it is written as a JSON array, or `nil` when it
	is written as an object. It must pass `isArray`. Its largest integer key is
	the length, not `#value`, because `#` is not reliable across holes (a `nil`
	in the middle). At least half the slots `1..length` must be filled. So
	`{1, nil, 3}` is an array, `[1, null, 3]` round-trips, and a sparse table
	like `{[1]=a, [2]=b, [10]=j}` becomes an object and no entry is dropped.
]=]
const function arrayLength(value: { [any]: any }): number?
	if not Array.isArray(value) then
		return nil
	end
	local count = 0
	local largest = 0
	for key in pairs(value) do
		count += 1
		if (key :: number) > largest then
			largest = key :: number
		end
	end
	if count * 2 >= largest then
		return largest
	end
	return nil
end

--[=[
	@within stringify
	@private
	Whether `key` is an array index: a canonical non-negative integer below `2^32 - 1`.
]=]
const function isIndexKey(key: string): boolean
	if not key:match("^%d+$") then
		return false
	end
	if #key > 1 and key:sub(1, 1) == "0" then
		return false
	end
	return (tonumber(key) :: number) < 4294967295
end

--[=[
	@within stringify
	@private
	Orders object keys: array indices ascending, then the other keys by string.
]=]
const function compareKeys(a: string, b: string): boolean
	const aIndex = isIndexKey(a)
	const bIndex = isIndexKey(b)
	if aIndex and bIndex then
		return (tonumber(a) :: number) < (tonumber(b) :: number)
	end
	if aIndex ~= bIndex then
		return aIndex
	end
	return a < b
end

type State = {
	replacer: ((string, any) -> any)?,
	propertyList: { string }?,
	gap: string,
	indent: string,
	stack: { [any]: boolean },
}

local serializeProperty

--[=[
	@within stringify
	@private
	Serializes an array's elements, one per line when `gap` is set.
]=]
const function serializeArray(state: State, array: { any }, count: number): string
	if count == 0 then
		return "[]"
	end
	const stepback = state.indent
	const indent = stepback .. state.gap
	const parts: { string } = {}
	for index = 1, count do
		state.indent = indent
		table.insert(parts, serializeProperty(state, tostring(index - 1), array[index]) or "null")
	end
	state.indent = stepback
	if state.gap == "" then
		return "[" .. table.concat(parts, ",") .. "]"
	end
	return "[\n" .. indent .. table.concat(parts, ",\n" .. indent) .. "\n" .. stepback .. "]"
end

--[=[
	@within stringify
	@private
	Serializes an object's own properties, in the key order described above.
]=]
const function serializeObject(state: State, object: { [any]: any }): string
	-- Map each JavaScript property key to the Luau key that holds its value.
	const rawKeys: { [string]: any } = {}
	for key in pairs(object) do
		const kind = type(key)
		if kind == "string" then
			rawKeys[key] = key
		elseif kind == "number" then
			rawKeys[Number.prototype.toString(key)] = key
		elseif kind == "boolean" then
			rawKeys[tostring(key)] = key
		end
	end

	const keys: { string } = {}
	if state.propertyList then
		for _, key in state.propertyList do
			if rawKeys[key] ~= nil then
				table.insert(keys, key)
			end
		end
	else
		for key in rawKeys do
			table.insert(keys, key)
		end
		table.sort(keys, compareKeys)
	end

	const stepback = state.indent
	const indent = stepback .. state.gap
	const colon = if state.gap == "" then ":" else ": "
	const parts: { string } = {}
	for _, key in keys do
		state.indent = indent
		const serialized = serializeProperty(state, key, object[rawKeys[key]])
		if serialized ~= nil then
			table.insert(parts, quote(key) .. colon .. serialized)
		end
	end
	state.indent = stepback

	if #parts == 0 then
		return "{}"
	end
	if state.gap == "" then
		return "{" .. table.concat(parts, ",") .. "}"
	end
	return "{\n" .. indent .. table.concat(parts, ",\n" .. indent) .. "\n" .. stepback .. "}"
end

serializeProperty = function(state: State, key: string, value: any): string?
	local current = value
	if type(current) == "table" and not Symbol.isSymbol(current) then
		const toJSON = current.toJSON
		if ECMAScript.IsCallable(toJSON) then
			current = toJSON(current, key)
		end
	end
	if state.replacer then
		current = state.replacer(key, current)
	end

	const kind = type(current)
	if current == nil then
		return nil
	elseif kind == "boolean" then
		return if current then "true" else "false"
	elseif kind == "string" then
		return quote(current)
	elseif kind == "number" then
		return formatNumber(current)
	elseif kind == "table" then
		if Symbol.isSymbol(current) then
			return nil
		end
		-- A raw JSON object is written as its text, exactly as given.
		if __raw.isRaw(current) then
			return (current :: any).rawJSON
		end
		if state.stack[current] then
			error(TypeError.new("Converting circular structure to JSON"), 2)
		end
		state.stack[current] = true
		local result: string
		if isOpaqueBuiltin(current) then
			result = "{}"
		else
			const length = arrayLength(current)
			if length ~= nil then
				result = serializeArray(state, current, length)
			else
				result = serializeObject(state, current)
			end
		end
		state.stack[current] = nil
		return result
	end
	-- Functions and userdata have no JSON form.
	return nil
end

--[=[
	@within stringify
	@private
	The indentation string from `space`: up to 10 spaces, or the first 10
	characters of a string, and nothing for anything else.
]=]
const function gapFrom(space: any): string
	if type(space) == "number" then
		if space ~= space or space < 1 then
			return ""
		end
		return string.rep(" ", math.min(10, math.floor(space)))
	end
	if type(space) == "string" then
		const cut = utf8.offset(space, 11)
		if cut then
			return space:sub(1, cut - 1)
		end
		return space
	end
	return ""
end

--[=[
	@within stringify
	@param value unknown -- the value to serialize
	@param replacer unknown? -- a function `(key, value) -> any` that replaces each value, or an array of the property names to keep
	@param space unknown? -- a number (up to 10 spaces) or a string (its first 10 characters) used to indent the output
	@return string? -- the JSON text, or `nil` when `value` has no JSON form (`undefined`, a function, or a symbol)

	Throws a `TypeError` if `value` contains a cycle.

	:::note
	With a property-list `replacer`, only the listed keys are written for
	objects, in the listed order. Keys not in the object are skipped. Numbers
	in the list are converted to strings. Arrays are not filtered.
	:::
]=]
const function stringify(value: unknown, replacer: unknown?, space: unknown?): string?
	const state: State = {
		replacer = nil,
		propertyList = nil,
		gap = gapFrom(space),
		indent = "",
		stack = {},
	}

	if ECMAScript.IsCallable(replacer) then
		state.replacer = replacer :: any
	elseif Array.isArray(replacer) then
		const list: { string } = {}
		const seen: { [string]: boolean } = {}
		for _, item in replacer :: { any } do
			local name: string? = nil
			if type(item) == "string" then
				name = item
			elseif type(item) == "number" then
				name = Number.prototype.toString(item)
			end
			if name ~= nil and not seen[name] then
				seen[name] = true
				table.insert(list, name)
			end
		end
		state.propertyList = list
	end

	return serializeProperty(state, "", value :: any)
end

return stringify
