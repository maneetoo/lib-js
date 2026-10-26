--!strict

--[=[
	@class toUpperCase

	A Luau implementation of JavaScript's [`String.prototype.toUpperCase()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/toUpperCase).

	Converts a string to upper case.
]=]

const __shared = require("../__shared")
const __utf8 = require("../__utf8")

--[=[
	@within toUpperCase
	@param self unknown -- the string to convert
	@return string -- the string in upper case

	:::caution
	The case mapping is limited to ASCII, Latin-1, Greek and Cyrillic. It
	does not expand characters, so `"ß"` stays `"ß"` where JavaScript gives
	`"SS"`. Locale-specific mappings are not supported.
	:::
]=]
const function toUpperCase(self: unknown): string
	return __utf8.changeCase(__shared.thisString(self, "toUpperCase"), true)
end

return toUpperCase
