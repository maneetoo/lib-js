--!strict

--[=[
	@class isPrototypeOf
	A Luau implementation of JavaScript's [`Object.prototype.isPrototypeOf()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/isPrototypeOf).
	Intended to be installed as a method so it can be called as
	`self:isPrototypeOf(value)`. The prototype chain is modelled as the
	chain of `__index` links, exactly as in this library's
	`getPrototypeOf`.
]=]

--[=[
	@within isPrototypeOf
	@param self any -- the candidate prototype
	@param value any -- the object whose chain is searched
	@return boolean -- `true` if `self` appears in `value`'s chain

	Returns `false` for anything that is not a table or `userdata`,
	matching JavaScript, where primitives are never "inside" a chain.

	:::note
	Only table-valued `__index` links are followed; a function `__index`
	ends the chain. Cyclic chains (e.g. `setmetatable(Class, Class)` with
	`Class.__index = Class`) are detected and terminate with `false`
	instead of looping forever.
	:::
]=]
-- The next link in the chain, or nil when there is none.
local function parentOf(object: any): any
	const metatable = getmetatable(object)
	if type(metatable) ~= "table" then
		return nil
	end
	return (metatable :: any).__index
end

const function isPrototypeOf(self: any, value: any): boolean
	const kind = type(value)
	if kind ~= "table" and kind ~= "userdata" then
		return false
	end
    
	-- Floyd's cycle detection: `fast` advances two links per round and
	-- is the only pointer compared against `self` (every node `slow`
	-- visits was already visited by `fast`).
	local slow: any = value
	local fast: any = value
	while true do
		fast = parentOf(fast)
		if fast == nil then
			return false
		end
		if fast == self then
			return true
		end
		fast = parentOf(fast)
		if fast == nil then
			return false
		end
		if fast == self then
			return true
		end
		slow = parentOf(slow)
		if fast == slow then
			return false
		end
	end
end

return isPrototypeOf
