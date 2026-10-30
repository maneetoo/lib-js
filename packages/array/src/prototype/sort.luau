--!strict

--[=[
	@class sort

	A Luau implementation of JavaScript's [`Array.prototype.sort()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/sort).
]=]

const ECMAScript = require("../../ECMAScript")
const String = require("../../String")
const TypeError = require("../../Error").TypeError
const __shared = require("../__shared")
const esTypes = require("../../ES17-Types")

--[=[
	@within sort
	@param array Array<T> -- the array to sort in place
	@param compareFn ((a: T, b: T) -> number)? -- negative when `a` sorts first. Default: compare as strings.
	@return Array<T> -- `array`, after the sort

	Sorts in place, and the sort is stable. `nil` (`undefined`) elements are not
	passed to `compareFn`, and they go to the end, as in JS.

	The default comparison converts both values to strings and compares them by
	UTF-8 byte order. For ASCII this matches JS. For other characters it can
	differ in one narrow range (see the `Array` caution on strings).

	:::caution
	Trailing `nil` elements are removed from the array, because the length is
	`#array`.
	:::
]=]
const function sort<T>(array: esTypes.Array<T>, compareFn: ((a: T, b: T) -> number)?): esTypes.Array<T>
	if compareFn ~= nil and not ECMAScript.IsCallable(compareFn) then
		error(TypeError.new("The comparison function must be either a function or undefined"))
	end

	const length = #array
	local defined: esTypes.Array<T> = {}
	local count = 0
	local allStrings = true
	for index = 1, length do
		const value = array[index]
		if value ~= nil then
			count += 1
			defined[count] = value
			if type(value) ~= "string" then
				allStrings = false
			end
		end
	end

	if compareFn == nil and allStrings then
		-- Equal strings are the same value, so an unstable sort still gives the stable result.
		table.sort(defined :: esTypes.Array<string>)
	elseif compareFn == nil then
		-- Convert each element to its string key once, not once per comparison.
		local records: esTypes.Array<{ key: string, value: T }> = {}
		for index = 1, count do
			records[index] = { key = String(defined[index], nil), value = defined[index] }
		end
		const sorted = __shared.stableSort(
			records,
			function(a: { key: string, value: T }, b: { key: string, value: T }): number
				if a.key < b.key then
					return -1
				elseif a.key > b.key then
					return 1
				end
				return 0
			end
		)
		for index = 1, count do
			defined[index] = sorted[index].value
		end
	else
		const comparator = compareFn :: (T, T) -> number
		defined = __shared.stableSort(defined, function(a: T, b: T): number
			const result = comparator(a, b)
			if result ~= result then
				return 0
			end
			return result
		end)
	end

	for index = 1, count do
		array[index] = defined[index]
	end
	for index = count + 1, length do
		array[index] = nil
	end
	return array
end

return sort
