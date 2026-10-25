--!strict

--[=[
	@class OrdinaryToPrimitive
	@private

	ECMA-262 §7.1.1.1 `OrdinaryToPrimitive`.
	https://tc39.es/ecma262/#sec-ordinarytoprimitive

	Tries `toString` then `valueOf` for a string hint, and the reverse otherwise.
	If neither returns a primitive, it falls back to `String(O)`, which gives
	`"[object Object]"`, or a comma-joined string for a non-empty array-like table.

	:::caution
	JavaScript throws a `TypeError` here. This library falls back to the string
	form instead, so callers never see a table.
]=]

const IsCallable = require "./IsCallable"
const ToString = require "./ToString"
const Symbol = require "../Symbol"

--[=[
	@within OrdinaryToPrimitive
	@param O table
	@param hint "string" | "number"
	@return any
]=]
const function OrdinaryToPrimitive(O: any, hint: string): any
	const first = if hint == "string" then "toString" else "valueOf"
	const second = if hint == "string" then "valueOf" else "toString"
	for _, name in { first, second } do
		const method = O[name]
		if IsCallable(method) then
			const result = if type(method) == "function" then method(O) else method()
			if Symbol.isSymbol(result) then
				return result
			end
		end
	end
	return ToString(O)
end

return OrdinaryToPrimitive
