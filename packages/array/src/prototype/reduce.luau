--!strict

--[=[
	@class reduce

	A Luau implementation of JavaScript's [`Array.prototype.reduce()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/reduce).
]=]

const ECMAScript = require("../../ECMAScript")
const TypeError = require("../../Error").TypeError
const esTypes = require("../../ES17-Types")

--[=[
	@within reduce
	@param array Array<T> -- the array to fold
	@param callback (accumulator: U, value: T, index: number, array: Array<T>) -> U -- the fold step
	@param ... U? -- an optional initial accumulator
	@return U -- the final accumulator

	Folds the array from left to right. With no initial value, the first element
	is the starting accumulator. Throws a `TypeError` for an empty array with no
	initial value, as JS does.

	:::note
	Pass the initial value as an argument even when it is `nil`. The argument count
	is what decides whether an initial value was given.
	:::
]=]
const function reduce<T, U>(
	array: esTypes.Array<T>,
	callback: (accumulator: U, value: T, index: number, array: esTypes.Array<T>) -> U,
	...: U?
): U
	if not ECMAScript.IsCallable(callback) then
		error(TypeError.new("Array.prototype.reduce: callback is not a function"))
	end
	const length = #array
	const hasInitial = select("#", ...) > 0

	local accumulator: U
	local start: number
	if hasInitial then
		accumulator = (...) :: U
		start = 1
	else
		if length == 0 then
			error(TypeError.new("Reduce of empty array with no initial value"))
		end
		accumulator = (array[1] :: unknown) :: U
		start = 2
	end

	for index = start, length do
		accumulator = callback(accumulator, array[index], index - 1, array)
	end
	return accumulator
end

return reduce
