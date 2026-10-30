--!strict

--[=[
	@class reduceRight

	A Luau implementation of JavaScript's [`Array.prototype.reduceRight()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/reduceRight).
]=]

const ECMAScript = require("../../ECMAScript")
const TypeError = require("../../Error").TypeError
const esTypes = require("../../ES17-Types")

--[=[
	@within reduceRight
	@param array Array<T> -- the array to fold
	@param callback (accumulator: U, value: T, index: number, array: Array<T>) -> U -- the fold step
	@param ... U? -- an optional initial accumulator
	@return U -- the final accumulator

	Like `reduce`, but folds from right to left.
]=]
const function reduceRight<T, U>(
	array: esTypes.Array<T>,
	callback: (accumulator: U, value: T, index: number, array: esTypes.Array<T>) -> U,
	...: U?
): U
	if not ECMAScript.IsCallable(callback) then
		error(TypeError.new("Array.prototype.reduceRight: callback is not a function"))
	end
	const length = #array
	const hasInitial = select("#", ...) > 0

	local accumulator: U
	local start: number
	if hasInitial then
		accumulator = (...) :: U
		start = length
	else
		if length == 0 then
			error(TypeError.new("Reduce of empty array with no initial value"))
		end
		accumulator = (array[length] :: unknown) :: U
		start = length - 1
	end

	for index = start, 1, -1 do
		accumulator = callback(accumulator, array[index], index - 1, array)
	end
	return accumulator
end

return reduceRight
