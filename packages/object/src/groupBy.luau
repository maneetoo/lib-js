--!strict

--[=[
	@class groupBy

	A Luau implementation of JavaScript's [`Object.groupBy()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/groupBy).

	Groups the elements of an array according to the key a callback
	returns for each of them.
]=]

const esTypes = require("../ES17-Types")

--[=[
	@within groupBy
	@param items { V } -- the array to group
	@param callback (value: V, index: number) -> K -- computes the group key for each item
	@return { [K]: { V } } -- a table mapping each key to an array of the items that produced it
	Iterates `items` in order, invoking `callback(value, index)` for
	each one, and appends the value to the array stored under the
	returned key, creating that array lazily on first use so unused keys
	never appear in the result.
	:::note
	`index` is passed 1-based, following Luau array convention, whereas
	JavaScript's `Object.groupBy` callback receives a 0-based index.
	Adjust by hand (`index - 1`) inside `callback` if 0-based indices are
	needed for parity with existing JS logic being ported.
	:::
	:::note
	Items within each bucket preserve their original relative order from
	`items`, matching JavaScript's `groupBy` guarantee.
	:::
	:::caution
	JavaScript coerces every key to a property key, so `undefined`,
	`null` and `NaN` become the strings `"undefined"`, `"null"` and
	`"NaN"`. Luau cannot store `nil` or `NaN` as a table key at all, so a
	callback returning either raises an error naming the offending item
	instead of failing with the opaque "table index is nil".
	:::
]=]
const function groupBy<V, K>(
	items: esTypes.Array<V>,
	callback: (value: V, index: number) -> K
): esTypes.Table<K, esTypes.Array<V>>
	const result: esTypes.Table<K, esTypes.Array<V>> = {}
	for index, value in items do
		const key = callback(value, index)
		const bucket = result[key]
		if bucket == nil then
			-- Only the first item of a group lands here, and a `nil`/`NaN`
			-- key can never have a bucket, so this is the one place the
			-- key check is needed — zero cost for every later item.
			if key == nil or key ~= key then
				error(
					`groupBy: callback returned a {if key == nil then "nil" else "NaN"} key for item #{index}, which cannot be used as a table key`,
					2
				)
			end
			result[key] = { value }
		else
			bucket[#bucket + 1] = value
		end
	end
	return result
end

return groupBy
