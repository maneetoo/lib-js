--!strict

--[=[
	@class toString

	A Luau implementation of JavaScript's
	[`Symbol.prototype.toString()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/toString).

	Returns a string of the form `"Symbol(<description>)"`, with an
	empty description rendered as `"Symbol()"` — exactly as in
	JavaScript. Also invoked automatically by Luau's own `tostring()`,
	since every symbol's shared metatable wires `__tostring` to this
	same implementation.
]=]
return require("../constructor").toString
