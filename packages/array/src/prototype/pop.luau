--!strict

--[=[
	@class pop

	A Luau implementation of JavaScript's [`Array.prototype.pop()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/pop).
]=]

const esTypes = require "../../ES17-Types"

--[=[
	@within pop
	@param array Array<T> -- the array to modify in place
	@return T? -- the removed last element, or `nil` if the array is empty

	Removes the last element and returns it, in place.

	:::caution
	A trailing `undefined` (`nil`) cannot be stored, so `#arr` skips it. `pop`
	then removes the last real element, not the `undefined`. JS would return
	`undefined` here.
	:::
]=]
const function pop<T>(array: esTypes.Array<T>): T?
	const length = #array
	if length == 0 then
		return nil
	end
	const value = array[length]
	array[length] = nil
	return value
end

return pop
