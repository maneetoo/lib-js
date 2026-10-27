--!strict

--[=[
	@class seal

	A Luau implementation of JavaScript's [`Object.seal()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/seal).

	Forbids adding new keys to a table, marks it as sealed, and returns that
	same table.
]=]

const esTypes = require("../ES17-Types")
const denyAddition = require("./__denyAddition")

--[=[
	@within seal
	@param object T -- the table to seal
	@return T -- the same table, now sealed

	Does what `preventExtensions` does and additionally puts a
	`__sealed = true` marker into the table's own metatable copy, which is how
	`isSealed` recognises it. Both changes are made in a single metatable copy
	and a single `setmetatable` call. Sealing an already sealed table
	allocates nothing. The values of existing keys stay changeable, as in
	JavaScript. Frozen tables (already sealed) and non-table values are
	returned unchanged.

	Errors are raised in the same cases as `preventExtensions`: a metatable
	protected by `__metatable`, or one that already defines its own
	`__newindex`.

	:::caution
	JavaScript's `seal` also forbids *removing* keys. Luau cannot: removing a
	key is `t[key] = nil`, an ordinary write to an existing slot, and no
	metamethod fires for it. So a sealed table still lets keys be deleted
	(a deleted key cannot be added back, as with `preventExtensions`). If keys
	must never disappear, use `freeze`, which also forbids changing values.
	:::

	:::caution
	The marker lives in the metatable, so the limits of `preventExtensions`
	apply: `rawset` bypasses the restriction, `setmetatable` with another
	metatable removes it, and `getmetatable(object)` is no longer the table it
	was before.
	:::

	:::caution
	JavaScript can seal functions and other exotic objects; Luau cannot give
	a function a metatable, so a non-table `object` is returned unchanged.
	:::
]=]
const function seal<T>(object: T & esTypes.Table<any, any>): T
	if type(object) ~= "table" or table.isfrozen(object :: any) then
		return object :: T
	end

	const metatable = getmetatable(object :: any)
	local own: any

	if metatable == nil then
		own = {}
	elseif type(metatable) ~= "table" then
		error("seal: cannot seal an object whose metatable is protected by __metatable", 2)
	else
		const existing = rawget(metatable :: any, "__newindex")
		if existing == denyAddition then
			-- Already restricted by us; nothing to do if it is sealed too.
			if rawget(metatable :: any, "__sealed") == true then
				return object
			end
		elseif existing ~= nil then
			error("seal: cannot seal an object that already defines its own __newindex", 2)
		end
		-- Copy-on-write: never mutate a metatable another object may share.
		-- `table.clone` also yields an unfrozen table, so frozen shared
		-- metatables (common for classes) work too.
		own = table.clone(metatable :: any)
	end

	own.__newindex = denyAddition
	own.__sealed = true
	setmetatable(object :: any, own)

	return object
end

return seal
