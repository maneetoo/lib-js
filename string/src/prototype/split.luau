--!strict

--[=[
	@class split

	A Luau implementation of JavaScript's [`String.prototype.split()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/split).

	Splits a string into an array of substrings.
]=]

const ECMAScript = require "../../ECMAScript"
const __shared = require "../__shared"
const __toString = require "../__toString"
const __utf8 = require "../__utf8"

--[=[
	@within split
	@param self unknown -- the string to split
	@param separator unknown -- the text to split on (`nil` gives one element)
	@param limit unknown -- the maximum number of elements (default: no limit)
	@return { string } -- the parts, stored in a 1-based Luau array

	An empty separator splits between each code point. An empty string
	splits to `{}`, except when a non-empty separator is given, then `{ "" }`.

	:::note
	The result is a plain Luau array. Its indices are 1-based, as in every
	`Array` result stored in Luau. JavaScript's 0-based indices apply only to
	`Array` method callbacks and return values.
	:::

	:::caution
	Only string separators are supported. Regular expressions are not.
	:::
]=]
const function split(self: unknown, separator: unknown, limit: unknown): { string }
	const s = __shared.thisString(self, "split")
	const max = if limit == nil then 4294967295 else ECMAScript.ToUint32(limit)
	const parts: { string } = {}
	if max == 0 then
		return parts
	end

	if separator == nil then
		parts[1] = s
		return parts
	end

	const pattern = __toString(separator)
	const length = __utf8.length(s)

	if pattern == "" then
		local count = 0
		for index = 0, math.min(length, max) - 1 do
			count += 1
			parts[count] = __utf8.sub(s, index, index + 1)
		end
		return parts
	end

	if s == "" then
		parts[1] = ""
		return parts
	end

	const patternLength = __utf8.length(pattern)
	local count = 0
	local cursor = 0
	while count < max do
		const found = __utf8.find(s, pattern, cursor)
		if found == -1 then
			count += 1
			parts[count] = __utf8.sub(s, cursor, length)
			break
		end
		count += 1
		parts[count] = __utf8.sub(s, cursor, found)
		cursor = found + patternLength
	end

	return parts
end

return split
