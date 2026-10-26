--!strict

--[=[
	@class assign

	A Luau implementation of JavaScript's [`Object.assign()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/assign).

	Copies all own properties from one or more source tables into a
	target table, overwriting any existing keys, and returns the
	(mutated) target.
]=]

const esTypes = require("../ES17-Types")

--[=[
	@within assign
	@param target T -- the table that receives the copied properties
	@param ... { [any]: any }? -- any number of source tables to copy from
	@return T -- the same `target` table, now containing the merged properties

	Mutates `target` in place by copying every key/value pair from each
	source, in order, so that later sources overwrite earlier ones (and
	the target's own pre-existing keys). Returns `target` for chaining.
	Sources are read with `next` directly, so a custom `__iter`
	metamethod on a source is ignored and only genuine own keys are
	copied (like JavaScript, which only copies own properties). Writes
	to `target` go through its metatable as usual, so a `__newindex` on
	the target is honoured, much like a JS setter.

	:::caution
	This is a shallow copy: nested tables are copied by reference, not
	cloned. `nil` sources are silently skipped, matching JavaScript's
	treatment of `null`/`undefined` sources.
	:::
    
	:::caution
	Only table sources are supported. JavaScript also accepts strings
	(copying their indices) and silently ignores other primitives; here
	a non-table, non-`nil` source raises an error from `next`.
	:::
]=]
const function assign<T>(target: T & esTypes.Table<any, any>, ...: esTypes.Table<any, any>?): T
	-- Cast once instead of at every write; the cast costs nothing at
	-- runtime but a cast inside the loop would repeat it per key.
	const destination: any = target
	-- `select("#", ...)` / `select(index, ...)` are used instead of
	-- packing the varargs into `{ ... }`: the latter allocates a fresh
	-- table on every single call just to iterate over it once. Luau
	-- compiles `select(n, ...)` on the vararg directly, so this stays
	-- cheap.
	const sourceCount = select("#", ...)
	for index = 1, sourceCount do
		const source = select(index, ...)
		-- `nil` sources are skipped rather than erroring, mirroring how
		-- JavaScript's `Object.assign` treats `null`/`undefined` sources
		-- as no-ops instead of throwing.
		if source ~= nil then
			for key, value in next, source :: any do
				destination[key] = value
			end
		end
	end
	return target
end

return assign
