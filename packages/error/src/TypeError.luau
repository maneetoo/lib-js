--!strict

--[=[
	@class TypeError

	A Luau implementation of JavaScript's
	[`TypeError`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/TypeError).

	Thrown when a value is not of the type an operation expects.

	:::note
	`TypeError(message?, options?)` and `TypeError.new(message?, options?)` are
	equivalent. The constructor inherits statics from `Error`.
	:::
]=]

return require "./__hierarchy" .TypeError
