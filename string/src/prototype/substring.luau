--!strict

--[=[
	@class substring

	A Luau implementation of JavaScript's [`String.prototype.substring()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/substring).

	Extracts the text between two indices.
]=]

const ECMAScript = require "../../ECMAScript"
const __shared = require "../__shared"
const __utf8 = require "../__utf8"

--[=[
	@within substring
	@param self unknown -- the string to cut
	@param start unknown -- the first code point index (default `0`)
	@param finish unknown -- the index just past the last one (default: the end)
	@return string -- the text between the two indices

	Unlike `slice`, negative values count as `0`, and when `start` is greater
	than `finish` the two are swapped.
]=]
const function substring(self: unknown, start: unknown, finish: unknown): string
	const s = __shared.thisString(self, "substring")
	const length = __utf8.length(s)
	local from = __shared.clamp(ECMAScript.ToIntegerOrInfinity(start), 0, length)
	local to = if finish == nil then length else __shared.clamp(ECMAScript.ToIntegerOrInfinity(finish), 0, length)
	if from > to then
		from, to = to, from
	end
	return __utf8.sub(s, from, to)
end

return substring
