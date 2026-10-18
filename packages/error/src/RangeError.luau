--!strict

--[=[
	@class RangeError

	A Luau implementation of JavaScript's
	[`RangeError`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RangeError).

	Thrown when a value is outside the set or range of values an operation accepts.

	:::note
	`RangeError(message?, options?)` and `RangeError.new(message?, options?)` are
	equivalent. The constructor inherits statics from `Error`.
	:::
]=]

return require "./__hierarchy" .RangeError
