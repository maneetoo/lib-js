--!strict

--[=[
	@class copyWithin

	A Luau implementation of JavaScript's [`Array.prototype.copyWithin()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/copyWithin).
]=]

const ECMAScript = require("../../ECMAScript")
const esTypes = require("../../ES17-Types")

--[=[
	@within copyWithin
	@param array Array<T> -- the array to modify in place
	@param target number -- where to copy to
	@param start number? -- where to copy from (inclusive). Default `0`.
	@param finish number? -- where to stop copying (exclusive). Default: the length.
	@return Array<T> -- `array`, after the copy

	Copies the elements in `start .. finish` to position `target`, in place. Works
	the same way as JS `Array.prototype.copyWithin` when the ranges overlap.
]=]
const function copyWithin<T>(array: esTypes.Array<T>, target: number, start: number?, finish: number?): esTypes.Array<T>
	const length = #array
	const to = ECMAScript.ToClampedIndexOrDefault(target, length, 0)
	const from = ECMAScript.ToClampedIndexOrDefault(start, length, 0)
	const final = ECMAScript.ToClampedIndexOrDefault(finish, length, length)
	const count = math.min(final - from, length - to)
	if count <= 0 then
		return array
	end

	-- Copy in the direction that never overwrites a source element before it is read.
	if from < to and to < from + count then
		for offset = count - 1, 0, -1 do
			array[to + offset + 1] = array[from + offset + 1]
		end
	else
		for offset = 0, count - 1 do
			array[to + offset + 1] = array[from + offset + 1]
		end
	end

	return array
end

return copyWithin
