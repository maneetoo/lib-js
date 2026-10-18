--!strict

--[=[
	@class fromEntries
	A Luau implementation of JavaScript's [`Object.fromEntries()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/fromEntries).
	Builds a table out of an array of `{ key, value }` pairs — the
	inverse of `entries`.
]=]

const esTypes = require "../ES17-Types"

--[=[
	@within fromEntries
	@param entries { { any } } -- an array of two-element `{ key, value }` tables
	@return { [any]: any } -- a new table built from the given pairs

	Each element of `entries` is expected to be a two-element array-like
	table, where index `1` is the key and index `2` is the value
	(matching the shape produced by this library's `entries`). If the
	same key appears more than once, the last occurrence wins, matching
	JavaScript behaviour.
    
	:::caution
	JavaScript object keys are always coerced to strings (or symbols),
	so `null`/`undefined`/`NaN` are perfectly valid keys there. Luau has
	no such coercion and cannot store `nil` or `NaN` as a table key, so a
	pair whose key is `nil` or `NaN` is **not** silently dropped — it
	raises a clear error naming the offending entry, instead of failing
	deep inside the table assignment with the opaque "table index is nil".
	:::
]=]
const function fromEntries(entries: esTypes.Array<esTypes.Array<any>>): esTypes.Table<any, any>
	const result = {}
	for index, pair in entries do
		const key = pair[1]
		-- `nil` and `NaN` (the only value not equal to itself) are the two
		-- values Luau refuses as table keys. The check is a single
		-- comparison pair on the hot path; the message is only built on
		-- failure. Level 2 reports the error at the caller, not in here.
		if key == nil or key ~= key then
			error(`fromEntries: entry #{index} has a {if key == nil then "nil" else "NaN"} key, which cannot be used as a table key`, 2)
		end
		result[key] = pair[2]
	end
	return result
end

return fromEntries
