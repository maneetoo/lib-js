--!strict

--[=[
	@class toPrimitive

	A Luau implementation of JavaScript's
	[`Symbol.prototype[Symbol.toPrimitive]()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/Symbol.toPrimitive).

	Converts a symbol to a primitive value — trivially itself, since a
	symbol already *is* the primitive.
]=]

const constructor = require "../constructor"

--[=[
	@within toPrimitive
	@param self constructor.Symbol -- the symbol to convert
	@param hint string? -- ignored; accepted only for signature parity with the real `@@toPrimitive` contract
	@return constructor.Symbol -- `self`, unchanged

	Real engines call `obj[Symbol.toPrimitive](hint)` internally
	wherever a primitive value is needed from `obj` (e.g. during `+`,
	template literals, or `JSON.stringify`), with `hint` set to
	`"number"`, `"string"`, or `"default"`. A symbol's own
	`[Symbol.toPrimitive]` ignores `hint` entirely and always just
	returns itself — there is no "number" or "string" form of a symbol
	to prefer. `hint` is accepted here purely so the signature matches;
	it has no effect on the result.
]=]
const function toPrimitive(self: constructor.Symbol, hint: string?): constructor.Symbol
	if not constructor.isSymbol(self) then
		error(`toPrimitive: expected a Symbol, got {typeof(self)}`, 2)
	end
	return self
end

return toPrimitive
