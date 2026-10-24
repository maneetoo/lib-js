--!strict

--[=[
	@class ToString
	@private

  ECMA-262 §7.1.17 `ToString(argument)`.
	https://tc39.es/ecma262/#sec-tostring

	Implements the abstract operation `ToString(value)` from JavaScript. It is
	the coercion behind `String(value)`, string concatenation with `+`, and
	the `this` coercion of every `String.prototype` method.
]=]

const Number = require "../Number"
const Object = require "../Object"
const Symbol = require "../Symbol"
const esTypes = require "../ES17-Types"

const NATIVE_FUNCTION = "function () { [native code] }"

--[=[
	A table counts as array-like when it is non-empty and every key is a
	positive integer. This is the same heuristic `Array.isArray` uses, so
	`{}` is not array-like here and becomes `"[object Object]"`.
]=]
const function isArrayLike(value: esTypes.Table<unknown, unknown>): boolean
	local count = 0
	for key in next, value do
		if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
			return false
		end
		count += 1
	end
	return count > 0
end

--[=[
	Recursive worker for `ToString`. `seen` holds the arrays currently being
	joined. A cycle such as `t[1] = t` becomes an empty string, not infinite
	recursion.
]=]
const function convert(value: unknown, seen: esTypes.Table<any, boolean>): string
	const kind = type(value)

	if kind == "nil" then
		return "undefined"
	end
	if kind == "boolean" then
		return if value then "true" else "false"
	end
	if kind == "number" then
		return Number.prototype.toString(value :: number)
	end
	if kind == "string" then
		return value :: string
	end
	if kind == "function" then
		return NATIVE_FUNCTION
	end

	if kind == "table" then
		const tbl = value :: any

		if Symbol.isSymbol(tbl) then
			error("Cannot convert a Symbol value to a string")
		end

		-- `Array.prototype.toString` is `join(",")`. Plain tables are
		-- arrays when they look like arrays, so join them directly.
		if isArrayLike(tbl) then
			if seen[tbl] then
				return ""
			end
			seen[tbl] = true
			const length = #tbl
			const parts = table.create(length, "")
			for index = 1, length do
				const item = tbl[index]
				parts[index] = if item == nil then "" else convert(item, seen)
			end
			seen[tbl] = nil
			return table.concat(parts, ",")
		end

		-- ToPrimitive(value, "string"): try `toString`, then `valueOf`.
		-- Only a primitive result is accepted.
		for _, name in { "toString", "valueOf" } do
			const method = tbl[name]
			if type(method) == "function" then
				const result = method(tbl)
				if type(result) ~= "table" then
					return convert(result, seen)
				end
			end
		end

		return Object.prototype.toString(value)
	end

	-- userdata, thread, vector, buffer
	return tostring(value)
end

--[=[
	@within ToString
	@param value unknown -- the value to convert
	@return string -- the JavaScript string form of `value`

	Conversion rules, as in JavaScript:
	- `nil` becomes `"undefined"`.
	- `true` and `false` become `"true"` and `"false"`.
	- Numbers are formatted with `Number.prototype.toString`, so `-0` gives
	  `"0"` and `NaN` gives `"NaN"`.
	- Tables use their `toString` method, then `valueOf`. If neither gives a
	  primitive, the result is `"[object Object]"`.
	- Array-like tables are joined with `","`.

	:::caution
	A symbol is not converted. A `TypeError` is raised, as `ToString` does for
	symbols in JavaScript. `String(symbol)` is the explicit form that works.
	:::
]=]
const function toString(value: unknown): string
	return convert(value, {})
end

return toString
