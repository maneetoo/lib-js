--!strict

--[=[
	@class replaceAll

	A Luau implementation of JavaScript's [`String.prototype.replaceAll()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replaceAll).

	Replaces every occurrence of a substring.
]=]

const ECMAScript = require("../../ECMAScript")
const __shared = require("../__shared")
const __utf8 = require("../__utf8")

--[=[
	@within replaceAll
	@param self unknown -- the string to change
	@param search unknown -- the substring to replace
	@param replaceValue unknown -- a replacement string, or a function
	@return string -- the string with every match replaced

	Replacement rules are the same as for `replace`. Matches do not overlap.
	An empty `search` matches before every code point and at the end, as in
	JavaScript, so `"ab".replaceAll("", "-")` gives `"-a-b-"`.

	:::caution
	Only string patterns are supported. Passing a `RegExp` without the `g`
	flag throws in JavaScript. A pattern is always treated as a literal
	string here.
	:::
]=]
const function replaceAll(self: unknown, search: unknown, replaceValue: unknown): string
	const s = __shared.thisString(self, "replaceAll")
	const pattern = ECMAScript.ToString(search)
	const patternLength = __utf8.length(pattern)
	const length = __utf8.length(s)
	const isFunction = ECMAScript.IsCallable(replaceValue)
	const template = if isFunction then "" else ECMAScript.ToString(replaceValue)

	-- Collect the matches first, then build the result from the pieces between them.
	const positions: { number } = {}
	local count = 0
	if patternLength == 0 then
		for index = 0, length do
			count += 1
			positions[count] = index
		end
	else
		local from = 0
		while true do
			const found = __utf8.find(s, pattern, from)
			if found == -1 then
				break
			end
			count += 1
			positions[count] = found
			from = found + patternLength
		end
	end

	if count == 0 then
		return s
	end

	const parts: { string } = {}
	local partCount = 0
	local cursor = 0
	for index = 1, count do
		const position = positions[index]
		const before = __utf8.sub(s, cursor, position)
		const after = __utf8.sub(s, position + patternLength, length)

		local replacement: string
		if isFunction then
			replacement = ECMAScript.ToString((replaceValue :: any)(pattern, position, s))
		else
			replacement = __shared.expandReplacement(template, pattern, __utf8.sub(s, 0, position), after)
		end

		partCount += 1
		parts[partCount] = before
		partCount += 1
		parts[partCount] = replacement
		cursor = position + patternLength
	end
	partCount += 1
	parts[partCount] = __utf8.sub(s, cursor, length)

	return table.concat(parts)
end

return replaceAll
