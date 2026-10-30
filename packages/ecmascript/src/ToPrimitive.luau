--!strict

--[=[
	@class ToPrimitive
	@private

	ECMA-262 §7.1.1 `ToPrimitive(input[, preferredType])`.
	https://tc39.es/ecma262/#sec-toprimitive

	`preferredType` is `"string"`, `"number"`, or `nil` (default). Values that are
	already primitive, symbols included, come back unchanged. Functions and
	userdata are not objects here, so they also come back unchanged.

	The order is: `Symbol.toPrimitive`, then `ordinaryToPrimitive`.

	:::caution
	The `default` hint is treated as `"number"`, as JavaScript does for every
	built-in object except `Date`.
	:::

	:::caution
	If `Symbol.toPrimitive` returns an object, or a conversion method cannot
	produce a primitive, this raises an error. The library raises a plain Luau
	error rather than constructing a `TypeError`, so this abstract operation does
	not depend on the `Error` package.
	:::
]=]

const IsCallable = require("./IsCallable")
const OrdinaryToPrimitive = require("./OrdinaryToPrimitive")
const Symbol = require("../Symbol")

--[=[
	@within ToPrimitive
	@private
	Whether `value` is a JavaScript primitive, as far as Luau can represent one.
]=]
const function isPrimitive(value: any): boolean
	const kind = type(value)
	return kind == "nil" or kind == "boolean" or kind == "number" or kind == "string" or Symbol.isSymbol(value)
end

--[=[
	@within ToPrimitive
	@param input any
	@param preferredType ("string" | "number")?
	@return any
]=]
const function ToPrimitive(input: any, preferredType: ("string" | "number")?): any
	if Symbol.isSymbol(input) then
		return input
	end

	-- Functions and userdata are not objects here, so they come back unchanged.
	if type(input) ~= "table" then
		return input
	end

	const hint = preferredType or "number"
	const exoticToPrim = input[Symbol.toPrimitive]
	if exoticToPrim ~= nil then
		if not IsCallable(exoticToPrim) then
			error("Symbol.toPrimitive is not callable", 2)
		end
		-- Calling the value directly works for both functions and callable tables.
		const result = exoticToPrim(input, hint)
		if not isPrimitive(result) then
			error("Cannot convert object to primitive value", 2)
		end
		return result
	end

	return OrdinaryToPrimitive(input, hint)
end

return ToPrimitive
