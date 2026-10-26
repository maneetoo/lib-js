--!strict

--[=[
	@class URIError

	A Luau implementation of JavaScript's
	[`URIError`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/URIError).

	Thrown when a malformed URI is passed to a URI-handling function.

	:::note
	`URIError(message?, options?)` and `URIError.new(message?, options?)` are
	equivalent. The constructor inherits statics from `Error`.
	:::
]=]

return require("./__hierarchy").URIError
