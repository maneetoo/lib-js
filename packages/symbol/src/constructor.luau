--!strict

--[=[
	@class SymbolConstructor
	@private

	Internal support for `Symbol`: creating, recognizing, and
	describing the symbol values produced by calling
	`Symbol(description)`.

	:::note
	Every symbol shares a single, frozen metatable, built once by
	`setPrototype` when the `Symbol` module first loads, rather than
	each symbol getting its own freshly-allocated metatable and
	`__index` closure. Nothing about a symbol's behaviour depends on
	anything *other* than its own identity (used to key into
	`descriptions` below), so there's nothing to gain from a
	per-instance metatable — sharing one avoids two allocations (a
	metatable table, and an `__index` closure) on every single
	`Symbol(...)` call.
	:::

	:::note
	A symbol's description is stored in a private weak-keyed table local to
	this module, keyed by the symbol itself — never as a field *on* the
	symbol table. This is what makes `sym.description` behave like a
	genuine per-instance property despite every symbol sharing one
	metatable: the shared `__index` function consults this map
	dynamically on every access. The table is a plain `__mode = "k"` table
	rather than a `WeakMap`, because `WeakMap` requires `Symbol` (for its
	`Symbol.toStringTag`), and requiring it here would make a cycle. A
	`nil` description is stored as a sentinel. Using a weak table (rather
	than a strong one) is essential: an ordinary strong table would pin
	every symbol ever created alive for the program's entire lifetime
	purely because this module remembers its description, defeating the
	point of symbols being ordinary, collectible values.
	:::
]=]

export type Symbol = {
	read description: string?,
	read constructor: any,
	read toString: (self: Symbol) -> string,
	read valueOf: (self: Symbol) -> Symbol,
	read [any]: any,
}

export type SymbolPrototype = {
	constructor: any,
	toString: (self: Symbol) -> string,
	valueOf: (self: Symbol) -> Symbol,
	description: (self: Symbol) -> string?,
	toPrimitive: (self: Symbol, hint: string?) -> Symbol,
	[any]: any,
}

-- Stores a `nil` description as a sentinel, since `nil` cannot be a table value.
const NIL_DESCRIPTION = newproxy(false)
const descriptionStore: { [any]: any } = setmetatable({}, { __mode = "k" })

-- The `descriptions` API used below and exported. Same method names as the
-- `WeakMap` it replaces, so callers and `Symbol/prototype/description` are
-- unaffected.
const descriptions = table.freeze {
	has = function(_self: any, key: any): boolean
		return descriptionStore[key] ~= nil
	end,
	get = function(_self: any, key: any): string?
		const stored = descriptionStore[key]
		if stored == NIL_DESCRIPTION then
			return nil
		end
		return stored
	end,
	set = function(_self: any, key: any, description: string?)
		descriptionStore[key] = if description == nil then NIL_DESCRIPTION else description
	end,
}

local sharedMetatable: { __index: any, __tostring: any }? = nil

--[=[
	Reports whether `value` is a symbol produced by `create` below (as
	opposed to a plain table, or any other kind of value). Relies on
	`descriptions:has`, not `descriptions:get`, so a symbol created with
	no description at all (a `nil` value stored for it) is still
	correctly recognized as a symbol.
]=]
const function isSymbol(value: any): boolean
	return type(value) == "table" and descriptions:has(value)
end

const function toStringImpl(self: Symbol): string
	if not isSymbol(self) then
		error(`expected a Symbol, got {typeof(self)}`, 2)
	end

	const description = descriptions:get(self)
	return `Symbol({description or ""})`
end

const function valueOfImpl(self: Symbol): Symbol
	if not isSymbol(self) then
		error(`expected a Symbol, got {typeof(self)}`, 2)
	end

	return self
end

--[=[
	Builds and caches the single metatable shared by every symbol,
	resolving instance method lookups (`toString`, `valueOf`, ...)
	against `prototype`, and `description` lookups against the
	`descriptions` map above. Must be called exactly once, by
	`Symbol/init.lua`, after `Symbol.prototype` has been fully built but
	before any symbol (including the well-known symbols) is created.

    :::note
	Because `__index` falls through to `rawget(prototype, key)` for any
	key other than `"description"`, any field added to `prototype`
	*after* this function runs — including `constructor` and the
	computed `[Symbol.toStringTag]`/`[Symbol.toPrimitive]` entries that
	`Symbol/init.lua` wires in once they're available — is immediately
	visible on every existing and future symbol instance, with no need
	to re-run this function or touch already-created symbols.
	:::

	:::caution
	`__index` here is a *function*, not `prototype` installed directly
	as a table `__index`. This is deliberate, not an oversight — see
	`Symbol`'s class-level docs for the two behavioural consequences
	this has (one desirable, one a documented divergence from real JS).
	:::
]=]
const function setPrototype(prototype: SymbolPrototype)
	if sharedMetatable ~= nil then
		error("Symbol: setPrototype must only be called once", 2)
	end

	const metatable = {
		__index = function(self: Symbol, key: any): any
			if key == "description" then
				return descriptions:get(self)
			end
			return rawget(prototype, key)
		end,
		__tostring = toStringImpl,
	}

	table.freeze(metatable)
	sharedMetatable = metatable
end

--[=[
	Creates a new, unique symbol with the given optional `description`.
	`setPrototype` must have been called first (done once, automatically,
	by `Symbol/init.lua`).
]=]
const function create(description: string?): Symbol
	if sharedMetatable == nil then
		error("Symbol: internal error — setPrototype was never called before create", 2)
	end

	const symbol = setmetatable({} :: any, sharedMetatable :: any)
	descriptions:set(symbol, description)
	table.freeze(symbol)

	return symbol
end

return table.freeze {
	create = create,
	setPrototype = setPrototype,
	isSymbol = isSymbol,
	descriptions = descriptions,
	toString = toStringImpl,
	valueOf = valueOfImpl,
}
