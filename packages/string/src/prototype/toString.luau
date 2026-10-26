--!strict

--[=[
	@class toString

	A Luau implementation of JavaScript's [`String.prototype.toString()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/toString).

	Returns the string value itself.
]=]

--[=[
	@within toString
	@param self unknown -- the value to return
	@return string -- `self`, unchanged

	Unlike the other methods, this does not convert `self`. A non-string
	throws a `TypeError`, as JavaScript does for `String.prototype.toString`.
]=]
const function toString(self: unknown): string
	if type(self) ~= "string" then
		error("String.prototype.toString requires that 'this' be a String")
	end
	return self :: string
end

return toString
