--!strict

--[=[
	@class valueOf

	A Luau implementation of JavaScript's [`Object.prototype.valueOf()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/valueOf).

	Returns the value itself. Intended to be installed as a method so it can be
	called as `self:valueOf()`, mirroring JavaScript's `obj.valueOf()`.
]=]

--[=[
	@within valueOf
	@param self T -- the value the method is called on
	@return T -- `self` itself

	JavaScript's version converts `this` to an object and returns it, which for
	an object is the object itself. Luau never boxes primitives (see
	`Boolean.prototype.valueOf` and `Number.prototype.valueOf`), so there is
	nothing to convert: every value is returned unchanged.

	An error is raised when `self` is `nil`, as JavaScript raises a
	`TypeError` for `null`/`undefined`.
]=]
const function valueOf<T>(self: T): T
	if self == nil then
		error("valueOf: cannot convert undefined or null to object", 2)
	end
	return self
end

return valueOf
