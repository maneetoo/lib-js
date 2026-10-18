--!strict

--[=[
	@class ES17Types

	A types-only module (no runtime values, only `export type` aliases)
	collecting a set of JavaScript/TypeScript-flavoured structural
	types: the bare essentials (`Array<T>`, `Table<K, V>`), plus the
	higher-level shapes commonly reached for once code starts modelling
	JS idioms more closely — dictionaries, read-only views, positional
	pairs/triples, optional/nullable values, common function shapes
	(predicates, comparators, mappers, reducers), and a structural
	`Thenable<T>` matching this library's `Promise<T>`.

	:::caution
	Luau's type system has no conditional types, no mapped types, and no
	`keyof` operator. That rules out a faithful Luau version of several
	extremely common TypeScript utility types:

	- `Partial<T>` / `Required<T>` — these need a mapped type
	  (`{ [K in keyof T]?: T[K] }`) to turn *every* field of an
	  arbitrary `T` optional/required. Luau cannot iterate over a
	  table type's keys at the type level at all.
	- `Pick<T, K>` / `Omit<T, K>` / `Record<K, V>` with a union `K` —
	  same limitation; selecting a subset of fields needs `keyof` and
	  mapped types.
	- `Exclude<T, U>` / `Extract<T, U>` — these need conditional types
	  (`T extends U ? ... : ...`) to filter a union member-by-member.
	- `ReturnType<F>` / `Parameters<F>` — Luau has no `infer`-style
	  extraction from a function type.

	None of these are approximated here with something subtly wrong;
	they are simply omitted. If a specific, *concrete* shape is needed
	(e.g. "every field of `Foo` optional"), write that one struct type
	by hand instead of reaching for a generic mapped type.
	:::
]=]

--[=[
	@within ES17Types
	@type Array<T> = { T }

	A plain, 1-indexed Luau array of `T` — the structural stand-in for
	JavaScript's `Array<T>` / `T[]`.

	:::note
	Unlike a JS array, nothing here tracks a `.length` separately from
	the table's contents, and holes are not well-defined the way a
	sparse JS array's are — this is exactly Luau's native `{T}`, just
	named for readability at call sites modelling JS APIs.
	:::
]=]
export type Array<T> = { T }

--[=[
	@within ES17Types
	@type Table<K, V> = { [K]: V }

	A plain Luau lookup table keyed by `K` — the structural stand-in for
	a JavaScript object used as a map (`{ [key: K]: V }` in TS).
]=]
export type Table<K, V> = { [K]: V }

--[=[
	@within ES17Types
	@type Dictionary<V> = { [string]: V }

	A plain string-keyed lookup table — the common case of `Table<K, V>`
	where `K` is always `string`, matching how a JS object used as a
	map is most often shaped.
]=]
export type Dictionary<V> = { [string]: V }

--[=[
	@within ES17Types
	@type ReadonlyArray<T> = { read T }

	A read-only view of an array of `T`, matching TypeScript's
	`ReadonlyArray<T>`.

	:::note
	Unlike the earlier, documentation-only attempt at this type, `read`
	is an actual Luau type-checker feature: a value with this type
	cannot have any of its indices assigned to (`arr[1] = x` is a type
	error), the same way TypeScript rejects `readonlyArr[0] = x`.
	:::

	:::caution
	This is still compile-time only. It doesn't call `table.freeze`
	under the hood or stop code holding the *same table* through a
	differently-typed `{T}` reference from mutating it, and it doesn't
	prevent runtime code (or an `any`-typed access) from writing to it
	either. For actual runtime immutability, freeze the table with
	`table.freeze` (see this library's `Object.freeze`).
	:::
]=]
export type ReadonlyArray<T> = { read T }

--[=[
	@within ES17Types
	@type ReadonlyTable<K, V> = { read [K]: V }

	A read-only view of a `Table<K, V>`, matching TypeScript's
	`Readonly<Record<K, V>>` / a `{ readonly [key: K]: V }` index
	signature.

	:::note
	As with `ReadonlyArray`, `read` is enforced by the type checker:
	assigning into a value typed as `ReadonlyTable<K, V>` is a type
	error.
	:::

	:::caution
	Still compile-time only — see `ReadonlyArray`'s caution. Use
	`table.freeze` for real runtime immutability.
	:::
]=]
export type ReadonlyTable<K, V> = { read [K]: V }

--[=[
	@within ES17Types
	@type Nullable<T> = T?

	A value that may be absent, named to read naturally at call sites
	that are explicitly modelling JavaScript's `T | null` (as opposed to
	Luau's own, more general, "any value can be `nil`").
]=]
export type Nullable<T> = T?

--[=[
	@within ES17Types
	@type Optional<T> = T?

	Identical to `Nullable<T>`, provided as a separate name for call
	sites modelling an *optional* value/property (TS's `T | undefined`,
	or a `key?: T` field) rather than an explicitly nullable one —
	Luau's `nil` conflates both concepts, so this is a naming
	convenience, not a distinct type.
]=]
export type Optional<T> = T?

--[=[
	@within ES17Types
	@type Entry2<K, V> = () -> (K, V)

	A zero-argument function producing a positional `(K, V)` pair via
	Luau multiple returns — the closest available stand-in for a
	two-element tuple type.

	:::caution
	Luau has no standalone tuple type: a bare `(K, V)` is only
	meaningful in the *return-type position* of a function type
	(`() -> (K, V)`), never as a type in its own right — writing
	`type Entry2<K, V> = (K, V)` is a syntax error, since the parser
	treats `(K, V)` as the start of a function parameter list and then
	requires a `->` to follow. Wrapping it in a thunk, as done here, is
	the only way to give such a pair a reusable, named type.
	:::

	:::note
	This models the type of what you get back from `(k, v)`-style
	multiple-return functions (e.g. a custom key/value iterator), not
	the `{ key, value }` *table* shape this library's `Object.entries`
	returns — those two-element arrays are intentionally untyped
	(`{ any }`) precisely because a homogeneous array type can't express
	"index 1 is a `K`, index 2 is a `V`".
	:::
]=]
export type Entry2<K, V> = () -> (K, V)

--[=[
	@within ES17Types
	@type Entry3<A, B, C> = () -> (A, B, C)

	The three-element counterpart of `Entry2`, for positional triples
	produced via multiple return values. See `Entry2` for why this must
	be shaped as a thunk rather than a bare tuple.
]=]
export type Entry3<A, B, C> = () -> (A, B, C)

--[=[
	@within ES17Types
	@type Thunk<T> = () -> T

	A zero-argument function producing a `T` — commonly used for lazy
	values, default-value factories, and deferred computations.
]=]
export type Thunk<T> = () -> T

--[=[
	@within ES17Types
	@type Predicate<T> = (value: T, index: number, array: Array<T>) -> boolean

	A test function, as passed to things like `Array.prototype.filter`
	or `Array.prototype.some`/`every` in JS. `index` is 1-based,
	following Luau array convention, and `array` is the array currently
	being iterated — matching TypeScript's
	`(value: T, index: number, array: T[]) => boolean` signature in
	full, including the `array` back-reference most Luau ports of these
	callbacks tend to drop.

	:::note
	JS's version also accepts an optional `thisArg` to bind as `this`
	inside the callback; that's omitted here since Luau closures
	already capture their enclosing scope directly, making a separate
	`this`-binding parameter unnecessary.
	:::
]=]
export type Predicate<T> = (value: T, index: number, array: Array<T>) -> boolean

--[=[
	@within ES17Types
	@type Comparator<T> = (a: T, b: T) -> number

	An ordering function returning a negative number if `a` should sort
	before `b`, a positive number if `a` should sort after `b`, and `0`
	if they're equivalent — the exact contract of the callback passed to
	JS's `Array.prototype.sort`, which (unlike `map`/`filter`/`reduce`)
	never receives an index or the array itself.
]=]
export type Comparator<T> = (a: T, b: T) -> number

--[=[
	@within ES17Types
	@type Mapper<T, U> = (value: T, index: number, array: Array<T>) -> U

	A transform function, as passed to `Array.prototype.map`, matching
	TypeScript's `(value: T, index: number, array: T[]) => U` in full.
	`index` is 1-based, following Luau array convention (subtract 1 by
	hand for parity with JS's 0-based callback index); `array` is the
	original array being mapped.
]=]
export type Mapper<T, U> = (value: T, index: number, array: Array<T>) -> U

--[=[
	@within ES17Types
	@type Reducer<T, U> = (accumulator: U, value: T, index: number, array: Array<T>) -> U

	A fold/accumulate function, as passed to `Array.prototype.reduce`,
	matching TypeScript's
	`(previousValue: U, currentValue: T, currentIndex: number, array: T[]) => U`
	in full, `array` included. `index` is 1-based, following Luau array
	convention.
]=]
export type Reducer<T, U> = (accumulator: U, value: T, index: number, array: Array<T>) -> U

--[=[
	@within ES17Types
	@type Visitor<T> = (value: T, index: number, array: Array<T>) -> ()

	A side-effecting callback with no meaningful return value, as passed
	to `Array.prototype.forEach`, matching TypeScript's
	`(value: T, index: number, array: T[]) => void` in full. `index` is
	1-based, following Luau array convention.
]=]
export type Visitor<T> = (value: T, index: number, array: Array<T>) -> ()

--[=[
	@within ES17Types
	@type Thenable<T> = { read ["then"]: (self: any, onFulfilled: ((T) -> ())?, onRejected: ((any) -> ())?) -> any }

	A structural duck-type for "anything promise-shaped": a table
	exposing a callable `andThen`, matching how this library spells
	JS's `then` (see this library's `Promise<T>`). Any `Promise<T>`
	satisfies this shape automatically, but so does a hand-rolled table
	with the same method, which is the point — JS's `Promise.resolve`
	(and this library's) adopts *any* thenable, not just native
	promises, and `Thenable<T>` is what lets a function accept "either".

	:::note
	This is intentionally looser than `Promise<T>` itself (it only
	requires `andThen`, not `status`/`catch`/`finally`), to mirror how
	loosely JavaScript's own spec defines "thenable".
	:::
]=]
export type Thenable<T> = {
	read ["then"]: (self: any, onFulfilled: ((T) -> ())?, onRejected: ((any) -> ())?) -> any,
}

--[=[
	@within ES17Types
	@type Awaitable<T> = T | Thenable<T>

	A value that is either already a plain `T`, or a `Thenable<T>` that
	will eventually produce one — the shape most "accepts a value or a
	promise of one" APIs (including this library's `Promise.resolve`)
	are typed against.
]=]
export type Awaitable<T> = T | Thenable<T>

--[=[
	@within ES17Types
	@type IteratorResult<T> = { value: T?, done: boolean }

	The record an iterator's `next` returns. When `done` is `true`, `value` is `nil`.
]=]
export type IteratorResult<T> = {
	value: T?,
	done: boolean,
}

--[=[
	@within ES17Types
	@type Iterator<T> = { next: (self: Iterator<T>) -> IteratorResult<T> }

	An iterator that yields `T` values. Step it with `it.next(it)`. It is also its
	own `[Symbol.iterator]`.
]=]
export type Iterator<T> = {
	next: (self: Iterator<T>) -> IteratorResult<T>,
}

return table.freeze {}
