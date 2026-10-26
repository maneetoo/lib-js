--!strict

--[=[
	@class Iterate

	Accepted inputs:

	- `nil`: nothing happens. This matches `new Map(undefined)`.
	- a string: each code point, through `String.prototype[Symbol.iterator]`.
	- a table with a `Symbol.iterator` method: the method is called with the
	  table, and its iterator is stepped to the end.
	- a plain table with no `Symbol.iterator`: its elements `1 .. #t`, in order.
	  This keeps `{ ... }` arrays working.

	Anything else, including numbers, booleans, functions, and symbols, throws a
	`TypeError`.
]=]

const ECMAScript = require("./ECMAScript")
const TypeError = require("./Error").TypeError
const String = require("./String")
const Symbol = require("./Symbol")

--[=[
	@within iterate
	@private
	Steps `iterator` to the end, passing each value to `callback`.
]=]
const function drain<T>(iterator: any, callback: (value: T) -> ())
	while true do
		const step = iterator.next(iterator)
		if step.done then
			return
		end
		callback(step.value)
	end
end

--[=[
	@within Iterate
	@param iterable unknown -- the value to walk
	@param callback (value: T) -> () -- called once per element, in order
]=]
const function iterate<T>(iterable: unknown, callback: (value: T) -> ())
	if iterable == nil then
		return
	end

	const kind = type(iterable)
	if kind == "string" then
		drain(String.prototype[Symbol.iterator](iterable), callback)
		return
	end

	if kind ~= "table" or Symbol.isSymbol(iterable) then
		error(TypeError.new("object is not iterable"), 2)
	end

	const tbl = iterable :: any
	const method = tbl[Symbol.iterator]
	if method == nil then
		for index = 1, #tbl do
			callback(tbl[index])
		end
		return
	end

	if not ECMAScript.IsCallable(method) then
		error(TypeError.new("Symbol.iterator is not a function"), 2)
	end
	drain(method(tbl), callback)
end

return iterate
