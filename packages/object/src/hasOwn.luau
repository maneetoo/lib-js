--!strict

--[=[
	@class hasOwn

	A Luau implementation of JavaScript's [`Object.hasOwn()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/hasOwn).

	Checks whether a table has a given key as its own property,
	bypassing `__index` so inherited/prototype keys don't count.
]=]

const esTypes = require "../ES17-Types"

--[=[
	@within hasOwn
	@param object { [any]: any } -- the table to check
	@param key any -- the key to look for
	@return boolean -- `true` if `object` directly stores `key`

	Uses `rawget` so that, unlike a plain `object[key] ~= nil` check,
	values made available only through a metatable's `__index` are not
	considered "own" properties — mirroring the distinction JavaScript
	draws between `Object.hasOwn(obj, key)` and `key in obj`.

	:::caution
	Because this checks for presence via `rawget(object, key) ~= nil`,
	a key that is explicitly stored with a `nil` value is
	indistinguishable from a key that was never set at all — both report
	`false`. This matches ordinary Luau table semantics (`t[k] = nil`
	removes the entry), but differs from JavaScript, where
	`Object.hasOwn(obj, key)` is `true` even if `obj[key] === undefined`,
	as long as the key was actually assigned.
	:::
]=]
const function hasOwn(object: esTypes.Table<any, any>, key: any): boolean
	-- `rawget` deliberately skips the metatable's `__index`, so a key
	-- only reachable through a prototype chain correctly reports as not
	-- "owned" by `object` itself.
	return rawget(object, key) ~= nil
end

return hasOwn
