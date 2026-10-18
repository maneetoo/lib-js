--!strict

--[=[
	@class AggregateError

	A Luau implementation of JavaScript's
	[`AggregateError`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/AggregateError).

	Groups several errors into one, for example when every promise passed to
	`Promise.any` rejects.

	:::caution
	`errors` must be a Luau array (`{ ... }`), not an arbitrary iterable. It is
	copied, so later changes to the source array do not affect the error.
	:::
]=]

return require "./__hierarchy" .AggregateError
