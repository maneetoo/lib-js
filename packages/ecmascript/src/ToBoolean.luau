--!strict

--[=[
	@class ToBoolean
	@private

	ECMA-262 §7.1.2 `ToBoolean(argument)`.
	https://tc39.es/ecma262/#sec-toboolean

	:::caution
	This is **not** the same thing as Luau's own truthiness rules, and
	naively writing `value and true or false` would give the wrong
	answer for two extremely common cases: in Luau, only `nil` and
	`false` are falsy, so `0` and `""` are both truthy — but in
	JavaScript, `Boolean(0)` and `Boolean("")` are both `false`. This
	module implements JS's specific falsy list explicitly instead of
	relying on Luau's own truthiness at all.
	:::
]=]

const Number = require("../Number")

--[=[
	@within ToBoolean
	@param value any -- the value to coerce
	@return boolean -- `value` coerced the way `Boolean(value)` coerces it in JS

	Exactly six values are falsy, mirroring JS's `ToBoolean` precisely:
	`nil` (JS: `undefined`/`null`, which Luau's single `nil` conflates —
	see the caveat below), `false`, the numbers `0` and `-0`, `NaN`, and
	the empty string `""`. Every other value — including `{}`, numeric
	`0.0001`, the string `"false"`, and every function/table/thread/
	userdata — is truthy, exactly as in JS.

	:::caution
	Luau's single `nil` stands in for both of JS's `undefined` and
	`null`, both of which are falsy anyway, so this distinction doesn't
	actually matter for `ToBoolean` specifically (unlike, say,
	`Number`'s `nil`-handling, where the two diverge).
	:::

	:::caution
	An empty table (`{}`) is **truthy**, not falsy, matching JS exactly
	(`Boolean({})` and `Boolean([])` are both `true`) — a table is never
	treated as "empty means false" the way some loosely-typed languages
	might assume. Only the six values listed above are ever falsy.
	:::
]=]
const function ToBoolean(value: any): boolean
	if value == nil or value == false then
		return false
	end

	if type(value) == "number" then
		-- `value ~= value` catches NaN (the only value unequal to
		-- itself); `value == 0` catches both +0 and -0, since IEEE-754
		-- defines them as numerically equal.
		if Number.isNaN(value) or value == 0 then
			return false
		end
		return true
	end

	if value == "" then
		return false
	end

	return true
end

return ToBoolean
