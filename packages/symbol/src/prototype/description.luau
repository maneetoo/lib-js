--!strict

--[=[
	@class description

	A Luau implementation of JavaScript's
	[`Symbol.prototype.description`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/description)
	accessor, exposed here as a directly-callable function.
]=]

const constructor = require("../constructor")

--[=[
	@within description
	@param self constructor.Symbol -- the symbol to read the description of
	@return string? -- the symbol's description, or `nil` if it has none

	:::note
	In JavaScript, `description` is a getter property read without a
	call: `sym.description`. Accessing `.description` on a symbol
	produced by this library's `Symbol(...)` **also** works exactly
	that way, with no call needed at all — see `Symbol`'s class-level
	docs for how. This function is simply the direct-call form every
	other prototype method in this library supports
	(`Symbol.prototype.description(sym)`), offered for consistency and
	for call sites that prefer calling functions explicitly over
	relying on the property-access sugar.
	:::
]=]
const function description(self: constructor.Symbol): string?
	if not constructor.isSymbol(self) then
		error(`description: expected a Symbol, got {typeof(self)}`, 2)
	end
	return constructor.descriptions:get(self)
end

return description
