--!strict

--[=[
	@class toString

	A Luau implementation of JavaScript's
	[`Boolean.prototype.toString()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean/toString).

	Converts a boolean to the string `"true"` or `"false"`.
]=]

const TypeError = require("../../Error").TypeError

--[=[
	@within toString
	@param self boolean -- the boolean to convert
	@return string -- `"true"` or `"false"`

	:::note
	Equivalent to Luau's own `tostring(self)` for an actual `boolean`
	value — provided for parity with the rest of this library's
	`prototype` modules, and so code ported from JS that calls
	`Boolean.prototype.toString(x)` directly has something to call.
	:::
]=]
const function toString(self: boolean): string
	if type(self) ~= "boolean" then
		error(TypeError.new("Boolean.prototype.toString requires that 'this' be a Boolean"))
	end
	return if self then "true" else "false"
end

return toString
