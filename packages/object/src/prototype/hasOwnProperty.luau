--!strict

--[=[
	@class hasOwnProperty

	A Luau implementation of JavaScript's [`Object.prototype.hasOwnProperty()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/hasOwnProperty).

	Intended to be installed as a method (e.g. via this library's
	`setPrototypeOf`) so it can be called as `self:hasOwnProperty(key)`,
	mirroring JavaScript's `obj.hasOwnProperty(key)`.
]=]

--[=[
	@within hasOwnProperty
	@param self { [any]: any } -- the object the method is called on
	@param key any -- the key to check for
	@return boolean -- `true` if `self` directly stores `key`

	Equivalent to this library's standalone `hasOwn(self, key)`, exposed
	in method form so objects wired up with a `hasOwnProperty` field can
	be queried the same way `Object.prototype.hasOwnProperty` lets any
	JS object be queried, regardless of what it inherits.

	:::caution
	Uses `rawget` under the hood, so inherited keys (available only
	through `__index`) are not reported as "own" — and, as with
	`hasOwn`, a key explicitly set to `nil` is indistinguishable from a
	key that was never set.
	:::
]=]
return require("../hasOwn")
