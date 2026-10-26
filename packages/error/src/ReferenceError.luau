--!strict

--[=[
	@class ReferenceError

	A Luau implementation of JavaScript's
	[`ReferenceError`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/ReferenceError).

	Thrown when a variable that does not exist is referenced.

	:::note
	`ReferenceError(message?, options?)` and `ReferenceError.new(message?, options?)`
	are equivalent. The constructor inherits statics from `Error`.
	:::
]=]

return require("./__hierarchy").ReferenceError
