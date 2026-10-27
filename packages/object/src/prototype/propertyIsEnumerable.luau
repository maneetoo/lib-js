--!strict

--[=[
	@class propertyIsEnumerable

	A Luau implementation of JavaScript's [`Object.prototype.propertyIsEnumerable()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/propertyIsEnumerable).

	Intended to be installed as a method (e.g. via this library's
	`setPrototypeOf`) so it can be called as `self:propertyIsEnumerable(key)`,
	mirroring JavaScript's `obj.propertyIsEnumerable(key)`.
]=]

--[=[
	@within propertyIsEnumerable
	@param self { [any]: any } -- the object the method is called on
	@param key any -- the key to check for
	@return boolean -- `true` if `self` directly stores `key`

	JavaScript reports `true` only for an own key whose `enumerable`
	attribute is set. Luau tables have no such attribute — every key stored
	in a table is equally "enumerable" (see `getOwnPropertyDescriptor`) — so
	the answer is simply whether the key is an own key. This is the very same
	function as `hasOwnProperty` (re-exported, not copied, so the two can
	never drift apart and there is zero extra call overhead). It exists
	purely for API parity with JavaScript's `Object.prototype`.

	:::caution
	Uses `rawget` under the hood, so inherited keys (available only through
	`__index`) are not reported — and, as with `hasOwn`, a key explicitly set
	to `nil` is indistinguishable from a key that was never set.
	:::
]=]
return require("../hasOwn")
