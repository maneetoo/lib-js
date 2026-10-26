--!strict

--[=[
	@class fill

	A Luau implementation of JavaScript's [`Array.prototype.fill()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/fill).
]=]

const ECMAScript = require("../../ECMAScript")
const esTypes = require("../../ES17-Types")

--[=[
	@within fill
	@param array Array<T> -- the array to modify in place
	@param value T? -- the value to write
	@param start number? -- first position to write (inclusive). Default `0`.
	@param finish number? -- last position to write (exclusive). Default: the length.
	@return Array<T> -- `array`, after the write

	Sets the elements in `start .. finish` to `value`, in place. A `nil` value
	sets those elements to `undefined`.
]=]
const function fill<T>(array: esTypes.Array<T>, value: T?, start: number?, finish: number?): esTypes.Array<T>
	const length = #array
	const from = ECMAScript.ToClampedIndexOrDefault(start, length, 0)
	const to = ECMAScript.ToClampedIndexOrDefault(finish, length, length)
	for index = from + 1, to do
		array[index] = value :: T
	end
	return array
end

return fill
