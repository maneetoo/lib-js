--!strict

--[=[
	@class isExtensible

	A Luau implementation of JavaScript's [`Object.isExtensible()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/isExtensible).

	Reports whether new keys can still be added to a value.
]=]

const denyAddition = require("./__denyAddition")

--[=[
	@within isExtensible
	@param value any -- the value to check
	@return boolean -- `true` if new keys can still be added to `value`

	Returns `false` for:
	- a frozen table;
	- a table made non-extensible by this library's `preventExtensions`;
	- any non-table value. JavaScript reports `false` for primitives, and
	  functions/`userdata` cannot be given new keys through this library
	  either.

	Everything else is extensible.

	:::note
	A non-extensible table is recognised by the `__newindex` handler that
	`preventExtensions` installs. Consequently, `setmetatable`-ing a
	different metatable onto such a table makes it extensible again, and a
	table that is non-extensible only through its *own* `__newindex` logic is
	reported as extensible.
	:::

	:::caution
	When a table protects itself with `__metatable`, its real metatable cannot
	be read. `preventExtensions` refuses to work on such a table, so this
	library cannot have made it non-extensible, and it is reported as
	extensible (unless frozen).
	:::
]=]
const function isExtensible(value: any): boolean
	if type(value) ~= "table" then
		return false
	end
	if table.isfrozen(value) then
		return false
	end
	const metatable = getmetatable(value)
	-- `nil` means no metatable at all; a non-table result means the real
	-- metatable is hidden behind `__metatable`. Neither can carry our handler.
	if type(metatable) ~= "table" then
		return true
	end
	return rawget(metatable :: any, "__newindex") ~= denyAddition
end

return isExtensible
