--!strict

--[=[
	@class ErrorPrototype

	A Luau port of JavaScript's
	[`Error.prototype`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error/prototype):
	`name` (`"Error"`), `message` (`""`), and `toString`.
]=]

return require "./__hierarchy" .prototype
