--!strict

--[=[
	@class entries

	A Luau implementation of JavaScript's [`Object.entries()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/entries).

	Returns an array of `{ key, value }` pairs for a table's own
	properties, the structural counterpart to `keys` and `values`.
]=]

const esTypes = require("../ES17-Types")
const Symbol = require("../Symbol")

--[=[
	@within entries
	@param object { [K]: V } -- the table to extract entries from
	@return { { any } } -- an array of two-element `{ key, value }` tables

	Iterates `object` once with `next`, pushing a fresh two-element
	array for every own non-symbol key/value pair. A custom `__iter`
	metamethod is ignored, and symbol-keyed properties are skipped as in
	JavaScript.

	:::note
	Luau has no native `[key, value]` tuple/array literal the way
	JavaScript does, so each entry is represented as a two-element array
	`{ key, value }` (index `1` is the key, index `2` is the value)
	instead of a `[key, value]` tuple. Pair this with `fromEntries`,
	which expects entries in exactly this shape, to round-trip a table
	through a transformation.
	:::

	:::note
	As with `keys`/`values`, Luau's iteration order is unspecified for
	non-array-like tables, so the order of the returned entries should
	not be relied upon. Unlike separate `keys` and `values` calls,
	though, each entry keeps its key and value together, so nothing can
	fall out of alignment.
	:::
    
	:::note
	JavaScript always returns string keys (array indices become `"0"`,
	`"1"`, ...). Here keys keep their original Luau type.
	:::
]=]
const function entries<K, V>(object: esTypes.Table<K, V>): esTypes.Array<esTypes.Array<any>>
	const result: esTypes.Array<esTypes.Array<any>> = {}
	local count = 0
	for key, value in next, object do
		if not Symbol.isSymbol(key) then
			count += 1
			result[count] = { key, value }
		end
	end
	return result
end

return entries
