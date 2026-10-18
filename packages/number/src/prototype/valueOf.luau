--!strict

--[=[
	@class valueOf

	A Luau implementation of JavaScript's
	[`Number.prototype.valueOf()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/valueOf).

	Returns the primitive number value — itself.
]=]

--[=[
	@within valueOf
	@param self number -- the value to unwrap
	@return number -- `self` itself

	Luau has no boxed `Number` wrapper object the way JavaScript's
	`new Number(x)` does — this library's `Number(value)` always
	returns a plain primitive `number` (see `Number`'s class-level
	docs), so there is nothing to actually unwrap here. Provided purely
	for completeness alongside `Object.prototype.valueOf` and
	`Boolean.prototype.valueOf`.
]=]
const function valueOf(self: number): number
	return self
end

return valueOf
