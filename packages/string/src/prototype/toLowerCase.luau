--!strict

--[=[
	@class toLowerCase

	A Luau implementation of JavaScript's [`String.prototype.toLowerCase()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/toLowerCase).

	Converts a string to lower case.
]=]

const __shared = require "../__shared"
const __utf8 = require "../__utf8"

--[=[
	@within toLowerCase
	@param self unknown -- the string to convert
	@return string -- the string in lower case

	:::caution
	The case mapping is limited to ASCII, Latin-1, Greek and Cyrillic. It
	does not use Unicode's full case tables, and it does not apply special
	casing rules, such as the final sigma in context. Locale-specific
	mappings are not supported either.
	:::
]=]
const function toLowerCase(self: unknown): string
	return __utf8.changeCase(__shared.thisString(self, "toLowerCase"), false)
end

return toLowerCase
