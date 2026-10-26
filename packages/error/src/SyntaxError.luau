--!strict

--[=[
	@class SyntaxError

	A Luau implementation of JavaScript's
	[`SyntaxError`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SyntaxError).

	Thrown when text cannot be parsed as the expected syntax.

	:::note
	`SyntaxError(message?, options?)` and `SyntaxError.new(message?, options?)` are
	equivalent. The constructor inherits statics from `Error`.
	:::
]=]

return require("./__hierarchy").SyntaxError
