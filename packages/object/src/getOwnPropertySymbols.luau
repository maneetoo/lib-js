--!strict

--[=[
	@class getOwnPropertySymbols

	A Luau implementation of JavaScript's [`Object.getOwnPropertySymbols()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/getOwnPropertySymbols).

	Returns an array of a table's own keys that are symbols.
]=]

const esTypes = require("../ES17-Types")
const Symbol = require("../Symbol")

--[=[
	@within getOwnPropertySymbols
	@param object any -- the table to list symbol keys of
	@return { Symbol } -- an array containing every key of `object` that is a symbol

	Iterates with `next` directly, so a custom `__iter` metamethod is ignored
	and only genuine own keys are reported. A key counts as a symbol when
	`Symbol.isSymbol` says so.

	Non-table values have no own keys and yield an empty array. A `nil`
	`object` raises an error, as JavaScript does for `null`/`undefined`.

	:::note
	Luau's iteration order is unspecified, so — unlike JavaScript, which
	returns symbols in creation order — the order of the returned symbols
	should not be relied upon.
	:::

	Symbol keys are excluded from `keys`, `values`, `entries`, and
	`getOwnPropertyNames`, matching JavaScript.
]=]
const function getOwnPropertySymbols(object: any): esTypes.Array<Symbol.Symbol>
	if object == nil then
		error("getOwnPropertySymbols: cannot convert undefined or null to object", 2)
	end

	const result: esTypes.Array<Symbol.Symbol> = {}
	if type(object) ~= "table" then
		return result
	end

	local count = 0
	for key in next, object :: any do
		if Symbol.isSymbol(key) then
			count += 1
			result[count] = key :: Symbol.Symbol
		end
	end
	return result
end

return getOwnPropertySymbols
