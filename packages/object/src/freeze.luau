--!strict

--[=[
	@class freeze

	A Luau implementation of JavaScript's [`Object.freeze()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/freeze).

	Freezes a table in place so that new keys cannot be added and
	existing keys cannot be reassigned or removed, then returns that
	same table.
]=]

const esTypes = require("../ES17-Types")

--[=[
	@within freeze
	@param object T -- the table to freeze
	@return T -- the same table, now frozen

	Thin wrapper around Luau's native `table.freeze`, kept as a separate
	function for symmetry with `isFrozen` and the rest of the `Object.*`
	family, and so call sites read the same way JavaScript code would.

	:::caution
	Like `Object.freeze`, this is shallow: nested tables referenced by
	`object` are **not** themselves frozen. Freezing `{ inner = {} }`
	still allows `object.inner.x = 1`; only reassigning `object.inner`
	itself, or adding/removing keys directly on `object`, is prevented.
	:::

	:::note
	Non-table values are returned unchanged rather than erroring. In
	JavaScript, `Object.freeze` on a primitive is a no-op that returns
	the primitive as-is (primitives are already immutable); this mirrors
	that instead of failing on a `type()` mismatch inside
	`table.freeze`.
	:::
]=]
const function freeze<T>(object: T & esTypes.Table<any, any>): T
	-- Primitives (numbers, strings, booleans, `nil`, functions, etc.)
	-- are already immutable in every sense `Object.freeze` cares about,
	-- so there is nothing to do — matching JS, where freezing a
	-- primitive is a harmless no-op rather than an error.
	if type(object) ~= "table" then
		return object :: T
	end
	return table.freeze(object)
end

return freeze
