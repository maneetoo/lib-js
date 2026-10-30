--!strict

--[=[
	@class getOwnPropertyDescriptor

	A Luau implementation of JavaScript's [`Object.getOwnPropertyDescriptor()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/getOwnPropertyDescriptor).

	Returns the descriptor of a table's own key, or `nil` if it has none.
]=]

const shared = require("./__shared")

--[=[
	@within getOwnPropertyDescriptor
	@param object any -- the table to inspect
	@param key any -- the key to describe
	@return PropertyDescriptor? -- a fresh descriptor, or `nil` if `key` is not an own key of `object`

	Reads the key with `rawget`, so keys that are only reachable through
	`__index` are not own keys and yield `nil` (like `hasOwn`). The returned
	descriptor is a new table on every call.

	Luau tables have no per-key attributes, so the flags describe what is
	actually true rather than what was once requested through
	`defineProperty`:
	- `enumerable` is always `true`;
	- `writable` and `configurable` are `true`, except for a frozen table,
	  where they are `false`.

	Non-table values have no own keys and yield `nil`; they are not boxed.
	A `nil` `object` raises an error, as JavaScript does for
	`null`/`undefined`.

	:::caution
	Only data descriptors are ever returned (`get`/`set` do not exist), and
	a key holding `nil` is indistinguishable from an absent one — see `hasOwn`.
	:::
]=]
const function getOwnPropertyDescriptor(object: any, key: any): shared.PropertyDescriptor?
	if object == nil then
		error("getOwnPropertyDescriptor: cannot convert undefined or null to object", 2)
	end
	if type(object) ~= "table" then
		return nil
	end

	const value = rawget(object, key)
	if value == nil then
		return nil
	end
	return shared.describe(value, not table.isfrozen(object))
end

return getOwnPropertyDescriptor
