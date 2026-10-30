--!strict

--[=[
	@class structuredClone

	A Luau implementation of JavaScript's
	[`structuredClone()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/structuredClone).

	Creates a deep clone of a value using the structured clone algorithm:
	primitives, plain tables, this library's `Map`/`Set`/`Error` values, and
	Luau `buffer`s. Circular references are preserved. Functions, threads and
	other uncloneable values throw.

	```lua
	local structuredClone = require(path.to.structuredClone)

	local original = { list = { 1, 2, 3 } }
	const clone = structuredClone(original)
	clone.list[1] = 99
	print(original.list[1]) -- 1: the original is untouched
	``]

	:::caution
	JavaScript throws `DataCloneError`, a `DOMException`. There is no
	`DOMException` here, so a `TypeError` is thrown instead — same name
	JavaScript's own structured-clone polyfills fall back to.
	:::

	:::caution
	No prototype is preserved: JavaScript's algorithm also returns plain
	objects for class instances, and this one clones the *own* fields of any
	unknown table (a metatable, if present, is dropped). Clone a library
	`Map`/`Set`/`Error` explicitly and get the same kind back; anything else
	cloneable comes back as a plain table.
	:::

	:::caution
	The `options` argument is not supported: Luau `buffer`s cannot be
	transferred, only copied.
	:::

	:::caution
	JavaScript also clones `Date`, `RegExp`, typed arrays and a zoo of DOM
	types. Luau has none of those, so the cloneable set here is: `nil`,
	booleans, numbers, strings, `buffer`s, plain tables, `Map`, `Set`, and
	`Error` (with its subclasses; `cause` and `AggregateError.errors` are
	cloneable values and cloned along).
	:::
]=]

const TypeError = require("./Error").TypeError
const Map = require("./Map")
const Set = require("./Set")
const Symbol = require("./Symbol")

-- Clone map: every visited table maps to its clone, so shared references
-- stay shared in the clone and cycles terminate.
type Seen = { [any]: any }

--[=[
	@within structuredClone
	@private
	Reports whether `value` looks like an instance of `class`, by comparing a
	prototype method against the class's prototype table. Library collections
	dispatch through a metatable `__index` *function* (for `size`), so a plain
	prototype-chain walk cannot recognize them; method identity can.
]=]
local function isLibraryInstance(value: any, classTable: any, methodName: string): boolean
	if type(value) ~= "table" then
		return false
	end
	local method = value[methodName]
	return type(method) == "function" and method == (classTable.prototype :: any)[methodName]
end

-- Clone helpers call each other (tables contain library values, library
-- values contain tables), so the recursive worker is forward-declared.
local cloneValue: (value: any, seen: Seen) -> any

--[=[
	@within structuredClone
	@private
	Deep-clones a plain table. Array part and keyed part are both walked with
	`next`; `nil` values cannot exist, and `NaN` keys (the only other unstoreable
	key) cannot either, so every stored slot is visited exactly once.
]=]
local function cloneTable(value: any, seen: Seen): any
	const clone: any = {}
	seen[value] = clone
	for key, item in next, value :: any do
		clone[cloneValue(key, seen)] = cloneValue(item, seen)
	end
	return clone
end

--[=[
	@within structuredClone
	@private
	Deep-clones this library's `Map`, preserving key identity semantics: keys
	are cloned values (`nil` and `NaN` stay legal keys), and insertion order
	is replayed into the new map.
]=]
local function cloneMap(value: any, seen: Seen): any
	const MapLib = Map :: any
	const clone = MapLib.new()
	seen[value] = clone
	local entryIterator = value.entries(value)
	local step = entryIterator.next(entryIterator)
	while not step.done do
		const pair = step.value
		const clonedKey = cloneValue(pair[1], seen)
		clone.set(clone, clonedKey, cloneValue(pair[2], seen))
		step = entryIterator.next(entryIterator)
	end
	return clone
end

--[=[
	@within structuredClone
	@private
	Deep-clones this library's `Set`, preserving member identity semantics
	and insertion order.
]=]
local function cloneSet(value: any, seen: Seen): any
	const SetLib = Set :: any
	const clone = SetLib.new()
	seen[value] = clone
	local valueIterator = value.values(value)
	local step = valueIterator.next(valueIterator)
	while not step.done do
		clone.add(clone, cloneValue(step.value, seen))
		step = valueIterator.next(valueIterator)
	end
	return clone
end

--[=[
	@within structuredClone
	@private
	Deep-clones this library's `Error` (or subclass): a fresh instance of the
	same class, with the message preserved and `cause` / `errors` cloned as
	cloneable values. The `stack` of the clone is its own, freshly captured —
	JavaScript's algorithm does not copy stacks either.
]=]
local function cloneError(value: any, seen: Seen): any
	-- The class is found by name through Error's own static table.
	const ErrorLib = require("./Error") :: any
	local class = ErrorLib
	for _, className in
		{ "EvalError", "RangeError", "ReferenceError", "SyntaxError", "TypeError", "URIError", "AggregateError" }
	do
		if value.name == className then
			class = ErrorLib[className]
			break
		end
	end
	seen[value] = (class :: any).new(value.message)
	local clone = seen[value]

	local cause = value.cause
	if cause ~= nil then
		clone.cause = cloneValue(cause, seen)
	end
	local errors = value.errors
	if type(errors) == "table" then
		const errorsClone: { any } = {}
		for index, item in errors :: any do
			errorsClone[index] = cloneValue(item, seen)
		end
		clone.errors = errorsClone
	end
	return clone
end

--[=[
	@within structuredClone
	@private
	Copies the bytes of a Luau `buffer`, like JavaScript copies an
	`ArrayBuffer`'s contents.
]=]
local function cloneBuffer(value: buffer): buffer
	const length = buffer.len(value)
	const clone = buffer.create(length)
	buffer.copy(clone, 0, value, 0, length)
	return clone
end

--[=[
	@within structuredClone
	@private
	Clones one value. The `seen` table carries every already-cloned table, so
	a value appearing twice is cloned once, and cycles point at the clone.
]=]
function cloneValue(value: any, seen: Seen): any
	const kind = typeof(value)

	if kind ~= "table" and kind ~= "buffer" then
		-- Primitives (and functions, caught below) pass through by value.
		if kind == "function" or kind == "thread" or kind == "userdata" then
			error(TypeError.new(`structuredClone: {kind} could not be cloned`), 3)
		end
		return value
	end

	if kind == "buffer" then
		return cloneBuffer(value :: buffer)
	end

	-- A table: library values are recognized and cloned as their own kind.
	const tbl = value :: any
	if seen[tbl] ~= nil then
		return seen[tbl]
	end

	if isLibraryInstance(tbl, Map, "entries") then
		return cloneMap(tbl, seen)
	end
	if isLibraryInstance(tbl, Set, "add") then
		return cloneSet(tbl, seen)
	end
	if isLibraryInstance(tbl, require("./Error"), "toString") and type(tbl.message) == "string" then
		return cloneError(tbl, seen)
	end
	if Symbol.isSymbol(tbl) then
		-- Symbols are unique identities, not cloneable data.
		error(TypeError.new("structuredClone: symbol could not be cloned"), 3)
	end

	return cloneTable(tbl, seen)
end

--[=[
	@within structuredClone
	@param value any -- the value to clone
	@return any -- the deep clone

	Runs the structured clone algorithm over `value`. See the class
	documentation for the cloneable set and the documented divergences
	(no `options`, no prototype preservation, `TypeError` instead of
	`DataCloneError`).
]=]
const function structuredClone(value: any): any
	return cloneValue(value, {})
end

return structuredClone
