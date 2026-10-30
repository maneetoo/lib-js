--!strict

--[=[
	@class isSealed

	A Luau implementation of JavaScript's [`Object.isSealed()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/isSealed).

	Reports whether a value was sealed.
]=]

const denyAddition = require("./__denyAddition")

--[=[
	@within isSealed
	@param value any -- the value to check
	@return boolean -- `true` if `value` is sealed, frozen, or not a table

	A table is sealed when it is frozen, or when its metatable carries both
	the `__sealed` marker that `seal` puts there and the `__newindex`
	restriction of `preventExtensions`. The second condition guards against a
	marker left behind after the restriction was replaced.

	Non-table values are reported as sealed, matching JavaScript, where every
	primitive is. In JavaScript a function or other exotic object is an
	extensible object and reports `false`; Luau cannot give a function a
	metatable, so a function here is not extensible in any way this library
	can observe and reports `true` — the same answer `isFrozen` gives, keeping
	the JavaScript invariant that a frozen value is always sealed.

	:::caution
	Only tables sealed through this library are recognised. In JavaScript an
	object is also sealed once it is non-extensible and has no configurable
	keys, so a table made non-extensible with `preventExtensions` alone, even
	an empty one, reports `false` here.
	:::

	:::caution
	Sealing cannot stop keys from being removed (see `seal`), so this reports
	that the table was sealed, not that its set of keys is unchanged.
	:::
]=]
const function isSealed(value: any): boolean
	const kind = type(value)
	if kind ~= "table" then
		return true
	end
	if table.isfrozen(value) then
		return true
	end

	const metatable = getmetatable(value)
	if type(metatable) ~= "table" then
		return false
	end
	-- One metatable read serves both checks.
	return rawget(metatable :: any, "__sealed") == true and rawget(metatable :: any, "__newindex") == denyAddition
end

return isSealed
