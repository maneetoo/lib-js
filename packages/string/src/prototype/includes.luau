--!strict

--[=[
	@class includes

	A Luau implementation of JavaScript's [`String.prototype.includes()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/includes).

	Checks whether a string contains a substring.
]=]

const ECMAScript = require("../../ECMAScript")
const __shared = require("../__shared")
const __utf8 = require("../__utf8")

--[=[
	@within includes
	@param self unknown -- the string to search in
	@param search unknown -- the substring to look for
	@param position unknown -- the code point index to start from (default `0`)
	@return boolean -- `true` if `search` occurs at or after `position`

	:::caution
	Regular expressions are not supported. A pattern argument is converted
	to a string and matched literally. JavaScript throws for a `RegExp` here.
	:::
]=]
const function includes(self: unknown, search: unknown, position: unknown): boolean
	const s = __shared.thisString(self, "includes")
	const pattern = ECMAScript.ToString(search)
	const start = __shared.clamp(ECMAScript.ToIntegerOrInfinity(position), 0, __utf8.length(s))
	return __utf8.find(s, pattern, start) ~= -1
end

return includes
