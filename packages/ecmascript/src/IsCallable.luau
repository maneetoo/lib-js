--!strict

--[=[
	@class IsCallable
	@private

	ECMA-262 §7.2.3 `IsCallable(argument)`.
	https://tc39.es/ecma262/#sec-iscallable

	Returns `true` when `value` is a function, or a table with a `__call`
	metamethod. Everything else is not callable.

	:::note
	Userdata are not callable here, even when they carry `__call`.
	:::
]=]

--[=[
	@within IsCallable
	@param value any
	@return boolean
]=]
const function IsCallable(value: unknown): boolean
	if type(value) == "function" then
		return true
	end

	const kind = type(value)
	if kind == "table" or kind == "userdata" then
		const metatable = getmetatable(value :: any)
		if type(metatable) == "table" then
			return rawget(metatable, "__call") ~= nil
		end
	end

	return false
end

return IsCallable
