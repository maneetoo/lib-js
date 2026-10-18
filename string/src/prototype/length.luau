--!strict

--[=[
	@class length

	A Luau implementation of JavaScript's `String.prototype.length`.

	Returns the number of characters in a string.
]=]

const __shared = require "../__shared"
const __utf8 = require "../__utf8"

--[=[
	@within length
	@param self unknown -- the string to measure
	@return number -- the number of code points in the string

	:::caution
	In JavaScript `length` is a property. Here it is a function, because a
	Luau string cannot carry properties. Call it as
	`String.prototype.length(s)`.
	:::

	:::caution
	The result counts code points. JavaScript counts UTF-16 code units, so the
	two differ for characters outside the Basic Multilingual Plane.
	:::
]=]
const function length(self: unknown): number
	return __utf8.length(__shared.thisString(self, "length"))
end

return length
