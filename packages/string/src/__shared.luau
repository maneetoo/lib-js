--!strict

--[=[
	@class __shared
	@private

	Internal helpers shared by the `String` modules. Not part of the public
	API. Conversions to numbers go through `Number`.
]=]

const __toString = require "./__toString"

--[=[
	The largest string length that is allowed to be built, in bytes. This
	matches V8's limit. Methods that could build a larger string throw a
	`RangeError` instead.
]=]
const MAX_STRING_BYTES = 536870888

--[=[
	@private
	Clamps `value` into `[low, high]`.
]=]
const function clamp(value: number, low: number, high: number): number
	if value < low then
		return low
	end
	if value > high then
		return high
	end
	return value
end

--[=[
	@private
	The `this` coercion of a `String.prototype` method. `nil` throws, as
	JavaScript does. Any other value goes through `ToString`.
]=]
const function thisString(self: unknown, method: string): string
	if self == nil then
		error(`String.prototype.{method} called on null or undefined`)
	end
	return __toString(self)
end

--[=[
	@private
	Whitespace as `String.prototype.trim` defines it: ASCII whitespace, plus
	the Unicode space and line separators, and the BOM.
]=]
const function isWhitespace(codePoint: number): boolean
	if codePoint == 0x09 or codePoint == 0x0A or codePoint == 0x0B or codePoint == 0x0C or codePoint == 0x0D then
		return true
	end
	return codePoint == 0x20
		or codePoint == 0xA0
		or codePoint == 0x1680
		or (codePoint >= 0x2000 and codePoint <= 0x200A)
		or codePoint == 0x2028
		or codePoint == 0x2029
		or codePoint == 0x202F
		or codePoint == 0x205F
		or codePoint == 0x3000
		or codePoint == 0xFEFF
end

--[=[
	@private
	Expands `$$`, `$&`, `` $` `` and `$'` in a replacement template. Any other
	`$` stays as it is, because a string pattern has no capture groups.
]=]
const function expandReplacement(template: string, matched: string, before: string, after: string): string
	if not string.find(template, "$", 1, true) then
		return template
	end
	const out: { string } = {}
	local count, index = 0, 1
	const length = #template
	while index <= length do
		const character = string.sub(template, index, index)
		if character == "$" and index < length then
			const following = string.sub(template, index + 1, index + 1)
			count += 1
			if following == "$" then
				out[count] = "$"
			elseif following == "&" then
				out[count] = matched
			elseif following == "`" then
				out[count] = before
			elseif following == "'" then
				out[count] = after
			else
				out[count] = "$"
				index += 1
				continue
			end
			index += 2
		else
			count += 1
			out[count] = character
			index += 1
		end
	end
	return table.concat(out)
end

--[=[
	@private
	Raises a `RangeError` when `bytes` would exceed the string length limit.
]=]
const function checkStringLength(bytes: number)
	if bytes > MAX_STRING_BYTES then
		error("Invalid string length")
	end
end

return table.freeze {
	clamp = clamp,
	thisString = thisString,
	isWhitespace = isWhitespace,
	expandReplacement = expandReplacement,
	checkStringLength = checkStringLength,
}
