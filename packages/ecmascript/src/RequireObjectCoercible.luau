--!strict

--[=[
	@class RequireObjectCoercible
	@private

	ECMA-262 §7.2.1 `RequireObjectCoercible(argument)`.
	https://tc39.es/ecma262/#sec-requireobjectcoercible

	Returns `value` unchanged. Throws a `TypeError` when `value` is `nil`,
	which is Luau's stand-in for JavaScript `undefined` and `null`.

	:::caution
	Luau has one `nil`, so `undefined` and `null` cannot be told apart. Both
	throw here.
	:::
]=]

--[=[
	@within RequireObjectCoercible
	@param value any
	@return any
]=]
const function RequireObjectCoercible<T>(value: T?): T
	if value == nil then
		error("Cannot convert undefined or null to object")
	end
	return value :: T
end

return RequireObjectCoercible
