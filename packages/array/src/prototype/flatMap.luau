--!strict

--[=[
	@class flatMap

	A Luau implementation of JavaScript's [`Array.prototype.flatMap()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/flatMap).
]=]

const ECMAScript = require "../../ECMAScript"
const TypeError = require "../../Error" .TypeError
const esTypes = require "../../ES17-Types"
const isArray = require "../isArray"

--[=[
	@within flatMap
	@param array Array<T> -- the array to map over
	@param callback (value: T, index: number, array: Array<T>) -> unknown -- the mapping function
	@return Array<unknown> -- a new array, flattened one level

	Maps each element with `callback`, then spreads any array results one level.
	Equivalent to `map` followed by `flat(1)`, but in one pass.
]=]
const function flatMap<T>(array: esTypes.Array<T>, callback: (value: T, index: number, array: esTypes.Array<T>) -> unknown): esTypes.Array<unknown>
	if not ECMAScript.IsCallable(callback) then
        error(TypeError.new("Array.prototype.flatMap: callback is not a function"))
    end
	const result: esTypes.Array<unknown> = {}
	local count = 0
	const length = #array
	for index = 1, length do
		const mapped = callback(array[index], index - 1, array)
		if isArray(mapped) then
			const source = mapped :: esTypes.Array<unknown>
			for inner = 1, #source do
				count += 1
				result[count] = source[inner]
			end
		else
			count += 1
			result[count] = mapped
		end
	end
	return result
end

return flatMap
