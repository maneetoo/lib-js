--!strict

--[=[
	@class preventExtensions

	A Luau implementation of JavaScript's [`Object.preventExtensions()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/preventExtensions).

	Forbids adding new keys to a table while leaving its existing keys fully
	changeable and removable, then returns that same table.
]=]

const denyAddition = require("./__denyAddition")
const esTypes = require("../ES17-Types")

--[=[
	@within preventExtensions
	@param object T -- the table that should stop accepting new keys
	@return T -- the same table, now non-extensible

	Installs a `__newindex` handler that raises an error on every write to an
	absent key. Luau only consults `__newindex` for keys that are not in the
	table, so existing keys can still be reassigned or removed — exactly as
	with JavaScript. As in JavaScript, a removed key cannot be added back
	afterwards.

	Like `setPrototypeOf`, the change affects **only `object`**: when it
	already has a metatable, it is given its own copy (all other metamethods
	are carried over) and the copy is modified, so a metatable shared between
	many objects (a class) is never touched. Frozen tables, and non-table
	values, are returned unchanged: they are already non-extensible.

	Errors are raised when `object`'s metatable is protected by `__metatable`,
	or when it already has a `__newindex` of its own. That handler decides what
	assignments to absent keys mean (a redirect, a setter, validation), and
	silently replacing it would break those semantics.

	:::caution
	Because the metatable is replaced by a copy, `getmetatable(object)` is no
	longer the same table as before (`getmetatable(obj) == Class` becomes
	`false`).
	:::

	:::caution
	Only assignments through the table's metatable are intercepted.
	`rawset(object, key, value)` bypasses `__newindex`, and so does anything
	that writes raw table slots (`table.insert` into an absent index, for
	example). Also, `setmetatable` with another metatable lifts the
	restriction, and `setPrototypeOf` does **not** refuse to run on a
	non-extensible table (in JavaScript it throws).
	:::

	:::note
	Assigning `nil` to an absent key is allowed and does nothing — see
	`isExtensible`.
	:::
]=]
const function preventExtensions<T>(object: T & esTypes.Table<any, any>): T
	-- Primitives have nothing to restrict (JavaScript returns them as-is too),
	-- and a frozen table cannot get new keys, nor even a new metatable.
	if type(object) ~= "table" or table.isfrozen(object :: any) then
		return object :: T
	end

	const metatable = getmetatable(object :: any)

	if metatable == nil then
		setmetatable(object :: any, { __newindex = denyAddition })
		return object
	end

	if type(metatable) ~= "table" then
		error("preventExtensions: cannot restrict an object whose metatable is protected by __metatable", 2)
	end

	const existing = rawget(metatable :: any, "__newindex")
	if existing == denyAddition then
		return object
	end
	if existing ~= nil then
		error("preventExtensions: cannot restrict an object that already defines its own __newindex", 2)
	end

	-- Copy-on-write: never mutate a metatable another object may share.
	-- `table.clone` also yields an unfrozen table, so frozen shared
	-- metatables (common for classes) work too.
	const own: any = table.clone(metatable :: any)
	own.__newindex = denyAddition
	setmetatable(object :: any, own)

	return object
end

return preventExtensions
