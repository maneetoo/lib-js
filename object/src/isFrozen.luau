--!strict

--[=[
	@class isFrozen

	A Luau implementation of JavaScript's [`Object.isFrozen()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/isFrozen).

	Reports whether a value can no longer be mutated.
]=]

--[=[
	@within isFrozen
	@param value any -- the value to check
	@return boolean -- `true` if `value` is frozen (or isn't a table at all)

	Non-table values (numbers, strings, booleans, `nil`, functions,
	etc.) are always immutable in the sense `Object.isFrozen` cares
	about, so they're reported as frozen — matching JavaScript, where
	`Object.isFrozen` on any primitive always returns `true`, since
	primitives can't be mutated to begin with. Tables defer to Luau's
	native `table.isfrozen`.

	:::note
	This only reports the shallow frozen-ness of `value` itself. A table
	can be frozen while still containing unfrozen nested tables, since
	`freeze` (and `Object.freeze`) only ever freezes one level deep; this
	function reflects that same shallow truth rather than recursing.
	:::
]=]
const function isFrozen(value: any): boolean
	-- Primitives have no mutable state for `table.isfrozen` to inspect
	-- (and would error if passed to it), so they're short-circuited to
	-- `true` up front, exactly as JS does for its primitives.
	if type(value) ~= "table" then
		return true
	end
	return table.isfrozen(value)
end

return isFrozen
