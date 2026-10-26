--!strict
--!native

--[=[
	@class setPrototypeOf

	A Luau implementation of JavaScript's [`Object.setPrototypeOf()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/setPrototypeOf).

	Sets the value a table delegates to via `__index`, modelling
	JavaScript's prototype chain.
]=]

const esTypes = require("../ES17-Types")

-- Luau itself gives up on an `__index` chain after 100 hops, so there is
-- no point walking further when looking for a cycle.
const MAX_CHAIN_CHECK: number = 100

--[=[
	@within setPrototypeOf
	@param object T -- the table whose prototype should be changed
	@param prototype any? -- the new prototype (table/function, or `nil` to remove it)
	@return T -- the same `object`, mutated in place

	Sets `object`'s `__index` to `prototype`. Passing `nil` removes the
	prototype link, mirroring `Object.setPrototypeOf(obj, null)`.

	The change affects **only `object`**. Class-style code usually
	shares one metatable between every instance
	(`setmetatable(obj, Class)`), and writing `__index` into that shared
	table would silently re-parent every instance and corrupt the class
	itself. So when `object` already has a metatable, it is given its
	own copy (all other metamethods — `__newindex`, `__eq`,
	`__tostring`, etc. — are carried over) and the copy is modified.
	When it has none, a fresh one is created. If `__index` already equals
	`prototype`, nothing is touched and nothing is allocated.

	Errors, like JavaScript's `TypeError`, are raised when:
	- `prototype` is not a table, a function or `nil`;
	- `prototype`'s chain already contains `object` (a cyclic chain);
	- `object` is frozen;
	- `object`'s metatable is protected by `__metatable`.

	:::caution
	Because the metatable is replaced by a copy, `getmetatable(object)`
	is no longer the same table as before (`getmetatable(obj) == Class`
	becomes `false`), and metamethods added to the old shared metatable
	later are not seen by `object`.
	:::

	:::caution
	A non-table `__metatable` lock value (the usual `"locked"` string)
	is detected and reported clearly. A lock value that is itself a
	*table* is indistinguishable from a real metatable, so Luau's own
	"protected metatable" error is raised instead.
	:::
]=]
const function setPrototypeOf<T>(object: T & esTypes.Table<any, any>, prototype: any?): T
	const kind = type(prototype)
	if prototype ~= nil and kind ~= "table" and kind ~= "function" then
		error(`setPrototypeOf: prototype must be a table, a function or nil, got {kind}`, 2)
	end

	if table.isfrozen(object :: any) then
		error("setPrototypeOf: cannot set the prototype of a frozen object", 2)
	end

	-- JavaScript rejects cyclic prototype chains; in Luau a cycle would
	-- only surface later as a confusing "'__index' chain too long" on
	-- some unrelated missing-key read. Only a table prototype can lead
	-- back to `object`, and chains are normally one or two links long.
	if kind == "table" then
		local link: any = prototype
		for _ = 1, MAX_CHAIN_CHECK do
			if link == object then
				error("setPrototypeOf: cyclic prototype chain", 2)
			end
			const linkMetatable = getmetatable(link)
			if type(linkMetatable) ~= "table" then
				break
			end
			link = (linkMetatable :: any).__index
			if type(link) ~= "table" then
				break
			end
		end
	end

	const metatable = getmetatable(object :: any)

	if metatable == nil then
		-- Nothing to remove, and nothing worth allocating a metatable
		-- for when asked for "no prototype".
		if prototype ~= nil then
			setmetatable(object :: any, { __index = prototype })
		end
		return object
	end

	if type(metatable) ~= "table" then
		error("setPrototypeOf: cannot set the prototype of an object whose metatable is protected by __metatable", 2)
	end

	if rawget(metatable :: any, "__index") == prototype then
		return object
	end

	-- Copy-on-write: never mutate a metatable another object may share.
	-- `table.clone` also yields an unfrozen table, so frozen shared
	-- metatables (common for classes) work too.
	const own: any = table.clone(metatable :: any)
	own.__index = prototype
	setmetatable(object :: any, own)

	return object
end

return setPrototypeOf
