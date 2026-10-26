--!strict

--[=[
	@class valueOf

	A Luau implementation of JavaScript's
	[`Symbol.prototype.valueOf()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/valueOf).

	Returns the symbol itself. Unlike `Number`, there is no separate
	"boxed object" vs. "primitive" distinction for symbols in this
	library — a symbol produced by `Symbol(...)` *is* the value, in the
	only form this library has for it — so there is nothing to unwrap.
	Provided purely for completeness/parity with real
	`Symbol.prototype.valueOf`.
]=]
return require("../constructor").valueOf
