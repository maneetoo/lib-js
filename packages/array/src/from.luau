--!strict

--[=[
	@class from

	A Luau implementation of JavaScript's [`Array.from()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/from).
]=]

const ECMAScript = require("../ECMAScript")
const Symbol = require("../Symbol")
const TypeError = require("../Error").TypeError
const esTypes = require("../ES17-Types")
const isArray = require("./isArray")

--[=[
	@within from
	@param items unknown -- a string, an iterable, or an array-like object
	@param mapFn ((value: unknown, index: number) -> unknown)? -- applied to each element
	@return Array<unknown> -- a new array

	`Array.from(items, mapFn?)`. Accepts:

	- a string: each code point becomes one element (as UTF-8 characters)
	- an iterable: a table with a `[Symbol.iterator]` method
	- an array (see `isArray`): its elements
	- an array-like table with a `length` field and 0-based numeric keys

	Numbers and booleans give an empty array. `nil` throws a `TypeError`, as in JS.

	:::caution
	The result type is `Array<unknown>`. Luau has no way to tie it to the element
	type of an arbitrary iterable.
	:::
]=]
const function from(items: unknown, mapFn: ((value: unknown, index: number) -> unknown)?): esTypes.Array<unknown>
	if items == nil then
		error(TypeError.new("Array.from: undefined is not iterable"), 2)
	end

	if mapFn ~= nil and not ECMAScript.IsCallable(mapFn) then
		error(TypeError.new("Array.from: mapFn is not callable"), 2)
	end

	const result: esTypes.Array<unknown> = {}
	local count: number = 0
	const function add(value: unknown)
		const index = count
		const mapped = if mapFn == nil then value else mapFn(value, index)
		count += 1
		result[count] = mapped
	end

	if type(items) == "string" then
		for _, codepoint in utf8.codes(items :: string) do
			add(utf8.char(codepoint))
		end
		return result
	end

	if type(items) ~= "table" then
		return result
	end

	const object = items :: esTypes.Table<unknown, unknown>
	const iteratorFn = object[Symbol.iterator]
	if ECMAScript.IsCallable(iteratorFn) then
		const iterator = (iteratorFn :: (unknown) -> unknown)(items)
		if type(iterator) ~= "table" then
			error(TypeError.new("Array.from: iterator is not an object"), 2)
		end

		const nextFn = (iterator :: esTypes.Table<unknown, unknown>)["next"]
		if not ECMAScript.IsCallable(nextFn) then
			error(TypeError.new("Array.from: iterator.next is not callable"), 2)
		end

		while true do
			const record = (nextFn :: (unknown) -> unknown)(iterator)
			if type(record) ~= "table" then
				error(TypeError.new("Array.from: iterator result is not an object"), 2)
			end
			if (record :: esTypes.Table<unknown, unknown>)["done"] then
				break
			end
			add((record :: esTypes.Table<unknown, unknown>)["value"])
		end
		return result
	end

	if isArray(items) then
		for index = 1, #(items :: esTypes.Array<unknown>) do
			add((items :: esTypes.Array<unknown>)[index])
		end
		return result
	end

	const length = ECMAScript.ToLength(object["length"])
	for index = 0, length - 1 do
		add(object[index])
	end
	return result
end

return from
