--!strict

--[=[
	@class WeakMap

	A Luau implementation of JavaScript's
	[`WeakMap`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakMap).

	A collection of key/value pairs where the keys must be tables or
	userdata (JS: objects — see the note on `Key` below for one
	ES2023 exception this can't replicate), and where holding a value
	in the map does **not** prevent its key from being garbage
	collected. Once nothing outside the map still references a given
	key, that entry silently disappears on its own — exactly like a
	real `WeakMap`.

	:::note
	Implemented as a single table with a `__mode = "k"` metatable
	("weak keys"), which is Luau's native mechanism for exactly this
	behaviour: once a key used in such a table is unreachable from
	anywhere else, the garbage collector is free to drop that entry
	during its next collection cycle.
	:::

	:::note
	Unlike this library's planned `Map`, `WeakMap` intentionally has no
	`size` property and offers no way to iterate its entries
	(`keys`/`values`/`entries`/`forEach` are all absent here, exactly as
	they're absent from the real `WeakMap`). This isn't an oversight:
	since entries can vanish at any moment due to garbage collection,
	exposing a "count" or a way to list entries would report a
	snapshot that's misleading by construction — the real `WeakMap`
	omits these for the same reason.
	:::

	:::note
	`getOrInsert` and `getOrInsertComputed` mirror a relatively recent
	addition to JavaScript's `WeakMap` (the "Upsert" proposal), letting
	a "get, or insert-and-return a default" pattern be expressed in one
	call instead of a manual `has`-then-`get`-or-`set` dance — which, in
	real JS, also avoids a second hash lookup; the implementation here
	does the same, touching the underlying table at most once per call
	plus, on a miss, one write.
	:::

	:::note
	Only `set`, `getOrInsert`, and `getOrInsertComputed` validate that
	`key` is a table/userdata and raise an error otherwise. `get`,
	`has`, and `delete` deliberately do **not** — this matches real
	`WeakMap`, where only operations that might *insert* a record ever
	throw for an invalid key (per the spec's `CanBeHeldWeakly` check);
	`get`/`has`/`delete` on a key that could never have been stored
	simply report "not found" (`nil`/`false`/`false`), exactly as
	`new WeakMap().get(5)` quietly returns `undefined` in JS rather than
	throwing. In this implementation, that behaviour falls out
	naturally: reading a Luau table with any key (including `nil`) never
	errors, and writing `nil` to any key (a delete) never errors either
	— only writing a *non-nil* value under a `nil` key would, which
	`get`/`has`/`delete` never do.
	:::

	:::caution
	An invalid key raises a real `TypeError` from `Error/TypeError`, so
	code can catch it and test it with `instanceof`.
	:::

	:::note
	Both the shared method table backing every `WeakMap` instance (its
	`__index`) and the module table returned from this file (the one
	exposing `new`) are frozen with `table.freeze` before being handed
	out, so neither can be mutated or extended from outside — e.g.
	`WeakMap.set = function() end` has no effect and raises an error, as
	does adding a new static member. Individual *instances* returned by
	`new` are deliberately left unfrozen, since a map's entries are
	meant to be mutated over its lifetime via `set`/`delete` — only the
	shared implementation backing every instance is locked down, not
	each map's own data.
	:::
]=]

const Symbol = require "./Symbol"
const TypeError = require "./Error" .TypeError

--[=[
	@within WeakMap
	@type Key = any

	The accepted shape of a `WeakMap` key. Luau's type system has no
	dedicated `userdata` type annotation (`type()`/`typeof()` can
	*report* the runtime category `"userdata"`, but it isn't a type that
	can appear in an annotation the way `string` or `number` can), so
	this is typed as `any` and enforced at runtime instead — see `set`.

	:::note
	Since ES2023, JavaScript also permits *unregistered* `Symbol`
	values as `WeakMap` keys, in addition to objects. Luau has no
	native `Symbol` primitive, but this library's own `Symbol`
	implementation represents every symbol as a plain (frozen) table
	under the hood — so a symbol produced by this library's `Symbol(...)`
	already satisfies the table/userdata check below exactly like any
	other table, and works as a `WeakMap` key with no special-casing
	needed at all.
	:::
]=]
export type Key = any

export type WeakMap<K, V> = {
	set: (self: WeakMap<K, V>, key: K, value: V) -> WeakMap<K, V>,
	get: (self: WeakMap<K, V>, key: K) -> V?,
	has: (self: WeakMap<K, V>, key: K) -> boolean,
	delete: (self: WeakMap<K, V>, key: K) -> boolean,
	getOrInsert: (self: WeakMap<K, V>, key: K, defaultValue: V) -> V,
	getOrInsertComputed: (self: WeakMap<K, V>, key: K, compute: (key: K) -> V) -> V,
}

type Internal<K, V> = WeakMap<K, V> & {
	_entries: { [any]: any },
}

-- A unique sentinel used to represent a stored value of `nil`. Luau
-- tables cannot distinguish "no entry for this key" from "an entry
-- whose value happens to be nil" (`t[k] = nil` deletes the slot either
-- way), but JS's `WeakMap` can: `map.set(k, undefined)` followed by
-- `map.has(k)` is `true`. Storing this sentinel in place of an actual
-- `nil` value closes that gap, at the cost of one extra identity check
-- on every read. `newproxy(false)` produces a bare userdata with no
-- metatable, so comparing against it with `==` is a plain, fast
-- identity check that can never be hijacked by a custom `__eq`.
const NIL_SENTINEL = newproxy(false)

const prototype = {}
;(prototype :: any).__index = prototype

--[=[
	@within WeakMap
	@param self WeakMap<K, V>
	@param key K -- the key to associate a value with
	@param value V -- the value to store
	@return WeakMap<K, V> -- `self`, for chaining

	Stores `value` under `key`, overwriting any existing entry for that
	same key. Returns `self`, mirroring how JS's `WeakMap.prototype.set`
	returns the map itself to allow chained `.set(...).set(...)` calls.

	:::note
	Key identity is Luau's native raw table-key comparison (plain
	reference/value identity), which is never influenced by a key's own
	`__eq` metamethod — Lua/Luau only consult `__eq` for the `==`
	*operator* between two tables, not for hashing/comparing table keys
	during indexing. This happens to line up exactly with JS's
	`SameValue` semantics for object keys, so no extra care (e.g.
	`rawequal`) is needed here the way it was for this library's
	`instanceof`.
	:::

	:::caution
	`key` must be a table or userdata value, checked at runtime via
	Luau's `type()` — passing a number, string, boolean, function,
	`thread`, or `nil` raises an error, mirroring the
	`TypeError: Invalid value used as weak map key` JavaScript throws
	for a non-object key. This can't be enforced at the type level
	(see the `Key` type alias above for why), only at runtime.
	:::
]=]
const function set<K, V>(self: Internal<K, V>, key: K, value: V): WeakMap<K, V>
	-- Inlined rather than calling a shared `isValidKey` helper: this is
	-- the single most frequently hit path in the module, and avoiding
	-- the extra call frame is worth the small duplication against
	-- `getOrInsert`/`getOrInsertComputed` below.
	const keyType = type(key)
	if keyType ~= "table" and keyType ~= "userdata" then
		error(TypeError.new(`WeakMap: invalid key of type '{keyType}' (keys must be a table or userdata)`), 2)
	end

	-- `nil` can't be stored directly (see NIL_SENTINEL above for why);
	-- everything else is stored as-is.
	self._entries[key] = if value == nil then NIL_SENTINEL else value

	return self :: any
end

--[=[
	@within WeakMap
	@param self WeakMap<K, V>
	@param key K -- the key to look up
	@return V? -- the value stored under `key`, or `nil` if there is none

	:::note
	Returns `nil` both when `key` was never set, and when `key` *was*
	set with a value of `nil` — this function alone cannot distinguish
	the two, since `nil` is also Luau's "nothing here" value. Use `has`
	if that distinction matters.
	:::

	:::note
	Never raises an error, even for a non-table/userdata `key` (including
	`nil`) — see this class's top-level note on why only
	insertion-capable methods validate their key.
	:::
]=]
const function get<K, V>(self: Internal<K, V>, key: K): V?
	const value = self._entries[key]
	return if value == nil or value == NIL_SENTINEL then nil :: any else value
end

--[=[
	@within WeakMap
	@param self WeakMap<K, V>
	@param key K -- the key to check for
	@return boolean -- `true` if `key` currently has an entry in the map

	Unlike `get`, this correctly reports `true` even for a key whose
	stored value is `nil`, since presence is tracked independently of
	the sentinel substitution `get`/`set` perform internally.

	:::note
	Never raises an error for an invalid `key` — see `get`.
	:::
]=]
const function has<K, V>(self: Internal<K, V>, key: K): boolean
	return self._entries[key] ~= nil
end

--[=[
	@within WeakMap
	@param self WeakMap<K, V>
	@param key K -- the key to remove
	@return boolean -- `true` if an entry for `key` existed and was removed, `false` if there was nothing to remove

	Removes `key`'s entry, if any. Returns whether anything was
	actually deleted, matching JS's `WeakMap.prototype.delete` return
	value.

	:::note
	Never raises an error for an invalid `key` — see `get`.
	:::
]=]
const function delete_<K, V>(self: Internal<K, V>, key: K): boolean
	const entries = self._entries
	const existed = entries[key] ~= nil
	entries[key] = nil
	return existed
end

--[=[
	@within WeakMap
	@param self WeakMap<K, V>
	@param key K -- the key to look up (or insert a default for)
	@param defaultValue V -- the value to insert if `key` isn't already present
	@return V -- `key`'s existing value, or the newly-inserted `defaultValue`

	A Luau implementation of JavaScript's
	[`WeakMap.prototype.getOrInsert()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakMap/getOrInsert).

	If `key` already has an entry — even one whose value is `nil` — that
	existing value is returned unchanged and nothing is inserted.
	Otherwise, `defaultValue` is stored under `key` and then returned.

	:::note
	`defaultValue` is an ordinary argument, not a callback, so it is
	evaluated by the caller unconditionally on every call, whether or
	not it ends up being used — exactly as in JS, where the value
	passed to `getOrInsert` is likewise just a plain argument. If
	computing the default is expensive, prefer `getOrInsertComputed`,
	which only computes it when `key` is actually missing.
	:::

	:::caution
	`key` must be a table or userdata value — passing anything else
	raises an error, exactly as `set` does.
	:::
]=]
const function getOrInsert<K, V>(self: Internal<K, V>, key: K, defaultValue: V): V
	const keyType = type(key)
	if keyType ~= "table" and keyType ~= "userdata" then
		error(TypeError.new(`WeakMap: invalid key of type '{keyType}' (keys must be a table or userdata)`), 2)
	end

	-- Only ever touches `_entries` once on a hit, or once-plus-a-write
	-- on a miss — not the two-or-three separate `_entries` accesses a
	-- naive `if self:has(key) then return self:get(key) end self:set(...)`
	-- would perform.
	const entries = self._entries
	const existing = entries[key]

	if existing ~= nil then
		return if existing == NIL_SENTINEL then nil :: any else existing
	end

	entries[key] = if defaultValue == nil then NIL_SENTINEL else defaultValue
	return defaultValue
end

--[=[
	@within WeakMap
	@param self WeakMap<K, V>
	@param key K -- the key to look up (or insert a computed default for)
	@param compute (key: K) -> V -- produces the default value, called only if `key` is missing
	@return V -- `key`'s existing value, or the freshly-computed and inserted value

	A Luau implementation of JavaScript's
	[`WeakMap.prototype.getOrInsertComputed()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakMap/getOrInsertComputed).

	If `key` already has an entry — even one whose value is `nil` — that
	existing value is returned unchanged, and `compute` is never called
	at all. Otherwise, `compute(key)` is invoked, its result is stored
	under `key`, and that result is returned.

	Prefer this over `getOrInsert` whenever producing the default value
	is expensive (or has side effects that should only happen on a
	genuine cache miss), since `compute` is only ever invoked on an
	actual miss.

	:::note
	If, reentrantly, `compute` itself inserts a value for this exact
	`key` (e.g. by calling `set`/`getOrInsert` on the same map before
	returning), this function still overwrites that entry with its own
	freshly-computed value afterwards and returns *that* value — it
	does not re-check for a reentrant insert and defer to it. This
	matches the real specification's behaviour exactly (per the
	`GetOrInsertComputed` abstract operation, the map is re-scanned
	after the callback returns and the found-or-new record's value is
	unconditionally set to the callback's result), so this is not a
	shortcut — it's the spec-correct outcome.
	:::

	:::caution
	`key` must be a table or userdata value — passing anything else
	raises an error, exactly as `set` does, *without* calling `compute`.
	:::

	:::caution
	If `compute` raises an error, that error propagates out of this
	function unchanged and nothing is inserted — a failed computation
	never leaves a partial or placeholder entry behind.
	:::
]=]
const function getOrInsertComputed<K, V>(self: Internal<K, V>, key: K, compute: (key: K) -> V): V
	const keyType = type(key)
	if keyType ~= "table" and keyType ~= "userdata" then
		error(TypeError.new(`WeakMap: invalid key of type '{keyType}' (keys must be a table or userdata)`), 2)
	end

	const entries = self._entries
	const existing = entries[key]

	if existing ~= nil then
		return if existing == NIL_SENTINEL then nil :: any else existing
	end

	const value = compute(key)
	entries[key] = if value == nil then NIL_SENTINEL else value
	return value
end

;(prototype :: any).set = set
;(prototype :: any).get = get
;(prototype :: any).has = has
;(prototype :: any).delete = delete_
;(prototype :: any).getOrInsert = getOrInsert
;(prototype :: any).getOrInsertComputed = getOrInsertComputed


--[=[
	@within WeakMap
	@return WeakMap<K, V> -- a new, empty weak map

	Creates an empty `WeakMap`. Unlike JS, there is no equivalent to
	`new WeakMap(iterable)` for seeding initial entries — Luau has no
	standard iterable-protocol object to accept here the way JS does
	(a `[Symbol.iterator]`-bearing value); call `set` for each entry
	individually after construction instead.

	:::note
	The returned instance itself is left unfrozen — only the shared
	method table backing it (locked above) is immutable. A map's own
	entries are meant to change over its lifetime via `set`/`delete`.
	:::
]=]
const function new_<K, V>(): WeakMap<K, V>
	const entries = setmetatable({}, { __mode = "k" })
	return setmetatable({
		_entries = entries,
	}, prototype) :: any
end

const WeakMap = {
	new = new_,
	prototype = prototype,
}
;(prototype :: any).constructor = WeakMap
;(prototype :: any)[Symbol.toStringTag] = "WeakMap"
table.freeze(prototype)
table.freeze(WeakMap)

return WeakMap
