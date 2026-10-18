--!strict

--[=[
	@class valueOf

	A Luau implementation of JavaScript's
	[`Boolean.prototype.valueOf()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean/valueOf).

	Returns the primitive boolean value — itself.
]=]

--[=[
	@within valueOf
	@param self boolean -- the value to unwrap
	@return boolean -- `self` itself

	Luau has no boxed `Boolean` wrapper object the way JavaScript does
	(no `new Boolean(x)` equivalent — see this library's `Boolean`
	class-level docs for why one isn't provided here either), so there
	is nothing to unwrap. This simply returns `self` unchanged, provided
	purely for completeness alongside `Number.prototype.valueOf` and
	`Object.prototype.valueOf`.
]=]
const function valueOf(self: boolean): boolean
	if type(self) ~= "boolean" then
		error(`valueOf: expected a boolean, got {typeof(self)}`, 2)
	end
	return self
end

return valueOf
