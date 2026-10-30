--!strict

--[=[
	@class OrdinaryToPrimitive
	@private

	ECMA-262 §7.1.1.1 `OrdinaryToPrimitive`.
	https://tc39.es/ecma262/#sec-ordinarytoprimitive

	Tries `toString` then `valueOf` for a string hint, and the reverse otherwise.
	Plain tables in Luau have no `Object.prototype`, so when neither method is
	present this falls back to `ToString(O)`, which gives `"[object Object]"`, or
	a comma-joined string for a non-empty array-like table.

	:::caution
	If a method is present but returns an object, this raises an error, as
	JavaScript does when no method produces a primitive. The library raises a
	plain Luau error rather than constructing a `TypeError`, so this abstract
	operation does not depend on the `Error` package.
	:::
]=]

const IsCallable = require("./IsCallable")
const Symbol = require("../Symbol")
const ToString = require("./ToString")

--[=[
	@within OrdinaryToPrimitive
	@private
	Whether `value` is a JavaScript primitive, as far as Luau can represent one.
]=]
const function isPrimitive(value: any): boolean
	const kind = type(value)
	return kind == "nil" or kind == "boolean" or kind == "number" or kind == "string" or Symbol.isSymbol(value)
end

--[=[
	@within OrdinaryToPrimitive
	@param O table
	@param hint "string" | "number"
	@return any
]=]
const function OrdinaryToPrimitive(O: any, hint: string): any
	const first = if hint == "string" then "toString" else "valueOf"
	const second = if hint == "string" then "valueOf" else "toString"
	local called = false
	for _, name in { first, second } do
		const method = O[name]
		if IsCallable(method) then
			called = true
			-- Calling the method directly preserves the receiver for functions
			-- and callable tables alike.
			const result = method(O)
			if isPrimitive(result) then
				return result
			end
		end
	end
	if called then
		error("Cannot convert object to primitive value", 2)
	end
	return ToString(O)
end

return OrdinaryToPrimitive
