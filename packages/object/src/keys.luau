--!strict

--[=[
	@class keys

	A Luau implementation of JavaScript's [`Object.keys()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/keys).

	Returns an array of a table's own keys.
]=]

const Symbol = require("../Symbol")
const esTypes = require("../ES17-Types")

--[=[
	@within keys
	@param object { [K]: V } -- the table to list keys of
	@return { K } -- an array containing every key found in `object`

	Iterates with `next` directly, which reads the table's real
	contents: a custom `__iter` metamethod is ignored, so only genuine
	own, non-symbol keys are reported (like JavaScript, which never
	consults a prototype or includes symbol keys here).

	:::note
	Luau's iteration order is unspecified for non-array-like tables, so
	— unlike JavaScript, which guarantees integer keys first in
	ascending order, then string keys in insertion order — the order of
	the returned keys here should not be relied upon. Sort the result
	yourself if a stable order matters for your use case.
	:::
    
	:::note
	JavaScript only ever returns string keys (array indices become
	`"0"`, `"1"`, ...). Here keys keep their original Luau type, so
	numeric and other non-string keys come back unchanged.
	:::
]=]
const function keys<K, V>(object: esTypes.Table<K, V>): esTypes.Array<K>
	const result: esTypes.Array<K> = {}
	local count = 0
	-- `next, object` is Luau's fastest iteration form, and an indexed
	-- store avoids a `table.insert` call per key.
	for key in next, object do
		if not Symbol.isSymbol(key) then
			count += 1
			result[count] = key
		end
	end
	return result
end

return keys
