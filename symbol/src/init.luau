--!strict

--[=[
	@class Symbol

	A Luau port of JavaScript's [`Symbol`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol):
	a constructor function, `Symbol.for`/`Symbol.keyFor` for the global
	symbol registry, the standard "well-known symbols"
	(`Symbol.iterator`, `Symbol.toPrimitive`, ...), and a
	`Symbol.prototype` holding `toString`/`valueOf`/`description`/
	`constructor`/`[Symbol.toPrimitive]`/`[Symbol.toStringTag]`.

	Every symbol is a unique value — `Symbol("x") == Symbol("x")` is
	`false`, exactly as in JS, since each call produces a brand-new
	value regardless of a shared description.

	:::caution
	Luau has no extensible primitive type system — only `nil`,
	`boolean`, `number`, `string`, `function`, `thread`, `table`, and
	`userdata` exist, and none of those is "symbol". This library
	represents a symbol as a frozen, otherwise-empty table carrying a
	shared metatable, which means `type(Symbol())` and
	`typeof(Symbol())` both report `"table"`, never `"symbol"`. There is
	no way to close this gap without the ability to add a genuinely new
	primitive kind to the language.
	:::

	:::note
	Despite the above, `instanceof(Symbol(), Symbol)` correctly reports
	`false` — matching real JS, where `Symbol() instanceof Symbol` is
	also `false`, since `instanceof` requires an *object* on its
	left-hand side and a symbol is a primitive. This isn't a coincidence:
	a symbol's shared metatable uses a *function* `__index` (see the
	internal `constructor` module), and this library's `instanceof` explicitly
	refuses to treat a function `__index` as a prototype-chain link, so
	the walk terminates immediately and reports no match — exactly the
	outcome real JS produces, just arrived at for a different underlying
	reason.
	:::

	:::caution
	The same function-`__index` choice that makes `instanceof` correct
	means `Object.getPrototypeOf(someSymbol)` returns that internal
	accessor *function*, not `Symbol.prototype` — diverging from real
	JS, where `Object.getPrototypeOf(Symbol())` returns
	`Symbol.prototype` (via `ToObject` boxing). This trade-off was
	chosen deliberately: getting `instanceof` right, and getting
	`sym.description` to work as a genuine call-free property, were
	both judged more valuable than `getPrototypeOf` parity for a type
	most code never calls `getPrototypeOf` on anyway. Reading
	`sym.constructor` or `sym[Symbol.toStringTag]`, by contrast, work
	correctly despite this — see the internal `constructor` module's 
	`__index` function, which falls through to `Symbol.prototype` for 
	any key other than `"description"`.
	:::

	:::note
	`sym.description` works as a real, call-free property access,
	exactly like JavaScript's own getter — unlike, say, `Number`, where
	reading the wrapped primitive out of a boxed instance requires an
	explicit `:valueOf()` call. `Symbol.prototype.description(sym)` also
	works, as the direct-call form consistent with the rest of this
	library.
	:::

	:::note
	Unlike this library's `Number`, calling `Symbol(...)` has only one
	behaviour — there is no separate "boxed instance" mode analogous to
	`new Number(x)`. This isn't a missing feature: real JavaScript
	explicitly forbids `new Symbol()` at all (`TypeError: Symbol is not
	a constructor`), so `Symbol`'s *only* legal call form in JS is the
	bare one this library already implements.
	:::

	:::caution
	A symbol's `description` must be passed as a Luau `string?` —
	unlike JavaScript, which coerces any non-`undefined` argument via
	`ToString` (so `Symbol(42)`'s description becomes `"42"`), this
	library does not attempt that coercion. Call `tostring(value)`
	yourself first if `value` isn't already a string. The same applies
	to the key passed to `Symbol.for`.
	:::

	:::caution
	`Symbol.for` cannot be written as `Symbol.for(key)` — `for` is a
	reserved keyword in Luau and cannot follow a `.` in field-access
	syntax. Use bracket syntax instead: `Symbol["for"](key)`.
	:::

	:::note
	Symbols registered via `Symbol["for"]` are held in a plain, strong
	(non-weak) internal table and are therefore never garbage collected
	for as long as the program runs — see the internal `_registry`
	module. This matches real JavaScript, where the global symbol
	registry is specified to persist for the realm's entire lifetime.
	Symbols created directly via `Symbol(description)`, by contrast, are
	*not* kept alive by this library and can be garbage collected
	normally once nothing else references them.
	:::

	:::caution
	The well-known symbols (`Symbol.iterator`, `Symbol.asyncIterator`,
	`Symbol.hasInstance`, `Symbol.isConcatSpreadable`,
	`Symbol.toPrimitive`, `Symbol.toStringTag`, `Symbol.unscopables`,
	`Symbol.match`, `Symbol.matchAll`, `Symbol.replace`,
	`Symbol.search`, `Symbol.species`, `Symbol.split`) are provided as
	plain, unique symbol values and nothing more. In real JavaScript,
	these are deeply load-bearing: the language's own `for...of`,
	spread syntax, `instanceof`, string methods, and more all
	internally look these symbols up on objects to customize their
	behaviour. Luau has no equivalent language-level dispatch hooks, so
	these symbols are entirely inert here as far as *this library's own
	runtime behaviour* goes — with one explicit, deliberate exception:
	`Symbol.prototype[Symbol.toStringTag]` is set to `"Symbol"`, so
	anything that specifically checks for a `[Symbol.toStringTag]`
	field (the way real `Object.prototype.toString` does) can still
	find it on a symbol. Code built *on top of* this library is free to
	define and consult its own such protocols using these same,
	recognizable, standard names.
	:::

	:::note
	`Symbol.name` is provided (`"Symbol"`) for introspection parity
	with real JS, where every native function/constructor carries a
	`.name`. `Symbol.length` is **not** provided: in real JS it reflects
	the constructor's declared-parameter arity (an intrinsic slot every
	JS function has), a concept Luau's table-plus-`__call` emulation of
	a "constructor" has no equivalent source of truth for — inventing an
	arbitrary number there would be noise, not a faithful port.
	:::

	:::note
	Both `Symbol` and `Symbol.prototype` are frozen with `table.freeze`
	before being returned, making the whole public surface immutable —
	no new static members can be added, and none of the existing ones
	(including `prototype` itself) can be reassigned.
	:::
]=]

const constructor = require "@self/constructor"
const __registry = require "@self/__registry"

export type Symbol = constructor.Symbol

type SymbolStatic = {
	prototype: constructor.SymbolPrototype,
	name: string,
	iterator: Symbol,
	asyncIterator: Symbol,
	hasInstance: Symbol,
	isConcatSpreadable: Symbol,
	toPrimitive: Symbol,
	toStringTag: Symbol,
	unscopables: Symbol,
	match: Symbol,
	matchAll: Symbol,
	replace: Symbol,
	search: Symbol,
	species: Symbol,
	split: Symbol,
	keyFor: (symbol: Symbol) -> string?,
	isSymbol: (value: any) -> boolean,
	[string]: any,
}

const prototype = require "@self/prototype"
constructor.setPrototype(prototype)

const Symbol = {} :: SymbolStatic
Symbol.prototype = prototype

--[=[
	@within Symbol
	@prop iterator Symbol
	@prop asyncIterator Symbol
	@prop hasInstance Symbol
	@prop isConcatSpreadable Symbol
	@prop toPrimitive Symbol
	@prop toStringTag Symbol
	@prop unscopables Symbol
	@prop match Symbol
	@prop matchAll Symbol
	@prop replace Symbol
	@prop search Symbol
	@prop species Symbol
	@prop split Symbol

	The standard "well-known symbols". See this class's top-level
	caution block: these are inert placeholders in this library (bar
	one exception), not language-level hooks.

	:::note
	Unlike symbols created via `Symbol.for`, the well-known symbols are
	**not** entries in the global symbol registry —
	`Symbol.keyFor(Symbol.iterator)` returns `nil`, exactly matching
	real JavaScript.
	:::

	:::note
	Each well-known symbol's `description` matches real JavaScript
	exactly, e.g. `Symbol.iterator.description == "Symbol.iterator"` and
	`tostring(Symbol.iterator) == "Symbol(Symbol.iterator)"`.
	:::
]=]
Symbol.iterator = constructor.create("Symbol.iterator")
Symbol.asyncIterator = constructor.create("Symbol.asyncIterator")
Symbol.hasInstance = constructor.create("Symbol.hasInstance")
Symbol.isConcatSpreadable = constructor.create("Symbol.isConcatSpreadable")
Symbol.toPrimitive = constructor.create("Symbol.toPrimitive")
Symbol.toStringTag = constructor.create("Symbol.toStringTag")
Symbol.unscopables = constructor.create("Symbol.unscopables")
Symbol.match = constructor.create("Symbol.match")
Symbol.matchAll = constructor.create("Symbol.matchAll")
Symbol.replace = constructor.create("Symbol.replace")
Symbol.search = constructor.create("Symbol.search")
Symbol.species = constructor.create("Symbol.species")
Symbol.split = constructor.create("Symbol.split")

Symbol.name = "Symbol"

--[=[
	@within Symbol
	@function for
	@param key string -- the registry key to look up or create a symbol for
	@return Symbol -- the symbol registered under `key`

	A Luau implementation of JavaScript's
	[`Symbol.for()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/for).

	Looks `key` up in the global symbol registry. If a symbol is
	already registered under `key`, that exact same symbol is returned
	every time. Otherwise, a new symbol is created, described by `key`,
	registered under it, and returned.

	:::caution
	Must be called as `Symbol["for"](key)`, not `Symbol.for(key)` — see
	this class's top-level caution block for why.
	:::
]=]
Symbol["for"] = function(key: string): Symbol
	if type(key) ~= "string" then
		error(`Symbol.for: key must be a string, got {typeof(key)}`, 2)
	end

	const existing = __registry.byKey[key]
	if existing ~= nil then
		return existing
	end

	const symbol = constructor.create(key)
	__registry.byKey[key] = symbol
	__registry.reverse[symbol] = key
	return symbol
end

--[=[
	@within Symbol
	@param symbol Symbol -- the symbol to look up
	@return string? -- the key `symbol` is registered under, or `nil` if it isn't registered

	A Luau implementation of JavaScript's
	[`Symbol.keyFor()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/keyFor).

	Returns the registry key `symbol` was registered under via
	`Symbol["for"]`, or `nil` if `symbol` was never registered —
	including for every well-known symbol, and for any symbol created
	directly via `Symbol(description)`, even one whose description
	happens to equal some registry key.
]=]
Symbol.keyFor = function(symbol: Symbol): string?
	if not constructor.isSymbol(symbol) then
		error(`keyFor: expected a Symbol, got {typeof(symbol)}`, 2)
	end
	return __registry.reverse[symbol]
end

Symbol.isSymbol = constructor.isSymbol
-- Closes the circular reference `Symbol.prototype.constructor` has on
-- `Symbol` itself, and wires in the two computed-key entries — all
-- three can only be filled in now that `Symbol` and the well-known
-- symbols both exist.
prototype.constructor = Symbol
prototype[Symbol.toStringTag] = "Symbol"
prototype[Symbol.toPrimitive] = prototype.toPrimitive

--[=[
	@within Symbol
	@function __call
	@param description string? -- an optional, human-readable description
	@return Symbol -- a new, unique symbol

	`Symbol(description)` and `Symbol()` behave identically (both give
	the new symbol no description), exactly as in JS, where
	`Symbol()` and `Symbol(undefined)` are likewise indistinguishable —
	so, unlike this library's `Number`, no special zero-argument
	handling is required here at all.
]=]
setmetatable(Symbol, {
	__call = function(_, description: string?): constructor.Symbol
		if description ~= nil and type(description) ~= "string" then
			error(`Symbol: description must be a string, got {typeof(description)}`, 2)
		end
		return constructor.create(description)
	end,
})

table.freeze(prototype)
table.freeze(Symbol)

return (Symbol :: ((description: string?) -> Symbol) & SymbolStatic)
