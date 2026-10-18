--!strict

--[=[
	@class of

	A Luau implementation of JavaScript's [`Array.of()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/of).
]=]

const esTypes = require "../ES17-Types"

--[=[
	@within of
	@param ... T? -- the elements
	@return Array<T> -- a new array of those elements, in order

	`Array.of(...)`. Unlike `new Array(n)`, a single number is an element, not a length.

	:::note
	`nil` arguments are stored as `undefined`. A trailing `nil` does not change the
	array's length. See `Array` for the length rule.
	:::
]=]
const function of<T>(...: T?): esTypes.Array<T>
	return { ... } :: esTypes.Array<T>
end

return of
