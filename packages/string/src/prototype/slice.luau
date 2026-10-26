--!strict

--[=[
	@class slice

	A Luau implementation of JavaScript's [`String.prototype.slice()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/slice).

	Extracts a part of a string. Negative indices count from the end.
]=]

const ECMAScript = require("../../ECMAScript")
const __shared = require("../__shared")
const __utf8 = require("../__utf8")

--[=[
	@within slice
	@param self unknown -- the string to cut
	@param start unknown -- the first code point index to include (default `0`)
	@param finish unknown -- the index just past the last one to include (default: the end)
	@return string -- the extracted part, or `""` when `start` is not before `finish`
]=]
const function slice(self: unknown, start: unknown, finish: unknown): string
	const s = __shared.thisString(self, "slice")
	const length = __utf8.length(s)
	const from = ECMAScript.ToClampedIndexOrDefault(start, length, 0)
	const to = ECMAScript.ToClampedIndexOrDefault(finish, length, length)
	return __utf8.sub(s, from, to)
end

return slice
