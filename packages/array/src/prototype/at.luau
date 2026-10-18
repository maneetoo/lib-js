--!strict

--[=[
	@class at

	A Luau implementation of JavaScript's [`Array.prototype.at()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/at).
]=]

const ECMAScript = require "../../ECMAScript"
const esTypes = require "../../ES17-Types"

--[=[
	@within at
	@param array Array<T> -- the array to read from
	@param index number? -- position, starting at 0. Negative values count from the end.
	@return T? -- the element, or `nil` if the position is out of range

	Returns the element at `index`, as JS `Array.prototype.at`. The receiver is the
	first argument, so call `Array.prototype.at(arr, -1)`.
]=]
const function at<T>(array: esTypes.Array<T>, index: number?): T?
	const length = #array
	local relative = ECMAScript.ToIntegerOrInfinity(index)
	if relative < 0 then
		relative += length
	end
	if relative < 0 or relative >= length then
		return nil
	end
	return array[relative + 1]
end

return at
