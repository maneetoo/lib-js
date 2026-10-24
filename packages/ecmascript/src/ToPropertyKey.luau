--!strict

--[=[
	@class ToPropertyKey
	@within AbstractOperations

	ECMA-262 §7.1.19 `ToPropertyKey(argument)`.
	https://tc39.es/ecma262/#sec-topropertykey
]=]

const ToPrimitive = require "./ToPrimitive"
const ToString = require "./ToString"
const Symbol = require "../Symbol"

--[=[
	@within ToPropertyKey
	@param value any
	@return any -- a string, number, or symbol key

	Symbols and numbers are kept as they are.

	:::caution
	Number keys are not converted to strings, so `t[1]` and `t["1"]` are
	different keys. This follows the library's raw-storage convention.
	:::
]=]
const function ToPropertyKey(value: any): any
	if Symbol.isSymbol(value) or type(value) == "number" then
		return value
	end
	const key = ToPrimitive(value, "string")
	if Symbol.isSymbol(key) then
		return key
	end
	return ToString(key)
end

return ToPropertyKey
