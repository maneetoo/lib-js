--!strict

--[=[
	@class EvalError

	A Luau implementation of JavaScript's
	[`EvalError`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/EvalError).

	Kept for parity with JavaScript. No code in this library throws it, since
	Luau has no `eval`.

	:::note
	`EvalError(message?, options?)` and `EvalError.new(message?, options?)` are
	equivalent. The constructor inherits statics from `Error`.
	:::
]=]

return require("./__hierarchy").EvalError
