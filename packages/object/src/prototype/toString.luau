--!strict

--[=[
	@class toString
	A Luau implementation of JavaScript's [`Object.prototype.toString()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/toString).
	Produces a generic, JavaScript-flavoured string tag for a value,
	deferring to a custom `__tostring` metamethod when one exists.
]=]

const TAGS: { [string]: string } = {
	["nil"] = "[object Undefined]",
	boolean = "[object Boolean]",
	number = "[object Number]",
	string = "[object String]",
	table = "[object Object]",
	["function"] = "[object Function]",
	userdata = "[object Userdata]",
	thread = "[object Thread]",
	vector = "[object Vector]",
	buffer = "[object Buffer]",
}
table.freeze(TAGS)

--[=[
	@within toString
	@param self any -- the value to describe
	@return string -- a string describing `self`

	If `self`'s metatable defines a `__tostring` of its own, Luau's
	`tostring` is used — matching how, in JavaScript, overriding
	`toString` on an object or its prototype takes priority over the
	default `Object.prototype.toString` behaviour. Otherwise returns a
	tag of the form `"[object <Type>]"`

	:::note
	Tags are pre-built constants, so the fallback path allocates nothing.
	:::

	:::caution
	Installing this very function as the metatable's `__tostring`
	(`__tostring = toString`) is safe: it is recognised and skipped, so
	it produces the default tag instead of recursing forever. A
	*wrapper* around it that calls back in cannot be detected, though.
	:::

	:::note
	There is no JS-style `[[Class]]` distinction (`Array`, `Date`,
	`RegExp`, ...): every table is a plain `Object`.
	:::
]=]
const function toString(self: any): string
	const kind = type(self)
	-- Only tables and userdata can carry a custom `__tostring`; skipping
	-- the metatable lookup for everything else is both faster and
	-- correct.
	if kind == "table" or kind == "userdata" then
		const metatable = getmetatable(self)
		if type(metatable) == "table" then
			const handler = (metatable :: any).__tostring
			-- `handler ~= toString` stops the infinite recursion that
			-- `setmetatable(obj, { __tostring = toString })` would
			-- otherwise cause (tostring -> __tostring -> toString -> ...).
			if handler ~= nil and handler ~= toString then
				return tostring(self)
			end
		end
	end
	return TAGS[kind] or `[object {kind:sub(1, 1):upper()}{kind:sub(2)}]`
end

return toString
