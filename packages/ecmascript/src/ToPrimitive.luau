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
]=]

const IsCallable = require "./IsCallable
const OrdinaryToPrimitive = "./OrdinaryToPrimitive"
const TypeError = require "../Error" .TypeError
const Symbol = require "../Symbol"

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
	const hint = preferredType or "number"
	const exoticToPrim = input[Symbol.toPrimitive]
	if exoticToPrim ~= nil then
		if not IsCallable(exoticToPrim) then
			error(TypeError.new("Symbol.toPrimitive is not callable"), 2)
		end
		const result = if type(exoticToPrim) == "function" then exoticToPrim(input, hint) else exoticToPrim()
		if not Symbol.isSymbol(result) then
			error(TypeError.new("Cannot convert object to primitive value"), 2)
		end
		return result
	end
	return OrdinaryToPrimitive(input, hint)
end

return ToPrimitive
