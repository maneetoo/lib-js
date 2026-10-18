--!strict

--[=[
	@class valueOf

	A Luau implementation of JavaScript's [`String.prototype.valueOf()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/valueOf).

	Returns the primitive string value itself.
]=]

--[=[
	@within valueOf
	@param self unknown -- the value to return
	@return string -- `self`, unchanged

	Luau has no boxed `String` object, so there is nothing to unwrap. A
	non-string throws a `TypeError`, as JavaScript does.
]=]
const function valueOf(self: unknown): string
	if type(self) ~= "string" then
		error("String.prototype.valueOf requires that 'this' be a String")
	end
	return self :: string
end

return valueOf
