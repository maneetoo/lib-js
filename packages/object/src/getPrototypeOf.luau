--!strict

--[=[
	@class getPrototypeOf

	A Luau implementation of JavaScript's [`Object.getPrototypeOf()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/getPrototypeOf).

	Retrieves the "prototype" a value delegates to, modelling Luau's
	`__index` metamethod as JavaScript's prototype link.
]=]

--[=[
	@within getPrototypeOf
	@param object any -- the value to inspect
	@return any -- the value `object`'s `__index` points to, or `nil`
    
	Looks up `object`'s metatable and returns its `__index` entry, which
	is how Luau conventionally implements prototype-style inheritance.
	Returns `nil` if `object` has no metatable at all, or if its
	metatable has no `__index`.

	:::note
	`__index` may be a function rather than a table (a computed
	fallback). That is returned as-is: it *is* what the object delegates
	to, but it is not a prototype object you can walk further.
	:::

	:::caution
	When a table protects itself with `__metatable`, `getmetatable`
	returns that protection value instead of the real metatable, and
	sandboxed Luau has no sanctioned way to see through it. A non-table
	lock value (the usual `"locked"` string) is detected and raises a
	clear error rather than being mistaken for "no prototype". A lock
	value that is itself a *table* is indistinguishable from a real
	metatable and will be read as one — do not use a table as the
	`__metatable` value if you want this function to stay accurate.
	:::

	:::caution
	JavaScript throws a `TypeError` for `Object.getPrototypeOf(null)` /
	`undefined`. Here `nil` simply has no metatable and yields `nil`.
	:::
]=]
const function getPrototypeOf(object: any): any
	const metatable = getmetatable(object)
	-- No metatable whatsoever: unambiguously, there is no prototype
	-- link to report.
	if metatable == nil then
		return nil
	end

	-- A non-table result means `__metatable` is set, hiding the real
	-- metatable from us. Say so plainly instead of pretending the
	-- object has no prototype. Level 2 blames the caller.
	if type(metatable) ~= "table" then
		error("getPrototypeOf: cannot read the prototype of an object whose metatable is protected by __metatable", 2)
	end
	return (metatable :: any).__index
end

return getPrototypeOf
