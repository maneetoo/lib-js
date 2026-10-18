--!strict

--[=[
	@class iterator

	A Luau implementation of JavaScript's [`String.prototype[Symbol.iterator]()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/@@iterator).

	Iterates over the code points of a string.
]=]

const Symbol = require "../../Symbol"
const __shared = require "../__shared"
const __utf8 = require "../__utf8"

--[=[
	@within iterator
	@param self unknown -- the string to iterate
	@return table -- an iterator, with a `next` method and `[Symbol.iterator]` returning itself

	Each step returns `{ value = <one code point as a string>, done = false }`.
	When the string is exhausted, it returns `{ value = nil, done = true }`.

	:::note
	Call it as `it.next(it)`, the same way as `Array`'s iterators. The
	iterator is not a Luau generic `for` iterator. Use a `while` loop over
	`next`.
	:::
]=]
const function iterator(self: unknown): any
	const codePoints = __utf8.decode(__shared.thisString(self, "[Symbol.iterator]"))
	local position = 0

	const result: any = {}
	result.next = function(_self: unknown): { value: string?, done: boolean }
		position += 1
		if position > #codePoints then
			return { value = nil, done = true }
		end
		return { value = __utf8.encode(codePoints, position, position), done = false }
	end
	result[Symbol.iterator] = function(itself: unknown): unknown
		return itself
	end
	return result
end

return iterator
