--!strict

--[=[
	@class SymbolRegistry
	@private

	The backing store for `Symbol.for`/`Symbol.keyFor`'s global symbol
	registry.

	:::note
	Deliberately **not** a `WeakMap`/weak table. JavaScript's global
	symbol registry is specified to persist for the entire lifetime of
	the realm (program) — a registered symbol is never eligible for
	garbage collection merely because nothing else references it
	anymore, precisely because the registry itself is meant to keep it
	reachable by its key forever. A weak registry would let registered
	symbols vanish unpredictably, breaking the one guarantee
	`Symbol.for("x") == Symbol.for("x")` depends on: that calling
	`Symbol.for` twice with the same key, no matter how much time or
	how many garbage collections pass in between, always returns the
	exact same symbol.
	:::
]=]

return {
	byKey = {} :: { [string]: any },
	reverse = {} :: { [any]: string },
}
