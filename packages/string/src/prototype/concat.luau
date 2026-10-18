--!strict

--[=[
	@class concat

	A Luau implementation of JavaScript's [`String.prototype.concat()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/concat).

	Joins the string with the string forms of its arguments.
]=]

const __shared = require "../__shared"
const __toString = require "../__toString"

--[=[
	@within concat
	@param self unknown -- the first string
	@param ... unknown -- the values to append, each converted with `ToString`
	@return string -- the concatenated string

	This is the same as `self .. tostring(args)`, but it follows JavaScript's
	conversion rules. For example, `nil` becomes `"undefined"`.
]=]
const function concat(self: unknown, ...: unknown): string
	const parts: { string } = { __shared.thisString(self, "concat") }
	for index = 1, select("#", ...) do
		parts[index + 1] = __toString((select(index, ...)))
	end
	return table.concat(parts)
end

return concat
