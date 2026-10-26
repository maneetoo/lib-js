--!strict

--[=[
	@class __toNumber
	@private

	Implements the coercion `Number(value)` performs on its argument —
	JavaScript's internal `ToNumber` abstract operation — used by the
	`Number` constructor.
]=]

const __staticProps = require("./__staticProps")
const Symbol = require("../Symbol")

const function trim(input: string): string
	local result = input:gsub("^%s+", "")
	result = result:gsub("%s+$", "")
	return result
end

--[=[
	Parses `input` as a full JS `StringNumericLiteral`: the *entire*
	(trimmed) string must form a single valid number, unlike
	`parseFloat`/`parseInt`, which happily parse just a leading prefix.
]=]
const function stringToNumber(input: string): number
	const trimmed = trim(input)
	if trimmed == "" then
		return 0
	end

	if trimmed == "Infinity" or trimmed == "+Infinity" then
		return __staticProps.POSITIVE_INFINITY
	end
	if trimmed == "-Infinity" then
		return __staticProps.NEGATIVE_INFINITY
	end

	-- Non-decimal literals (ES2015+) never allow a sign prefix, matching
	-- real engines: `Number("-0x10")` is `NaN`, not `-16`.
	const hexDigits = trimmed:match("^0[xX]([0-9a-fA-F]+)$")
	if hexDigits then
		return tonumber(hexDigits, 16) :: number
	end

	const octalDigits = trimmed:match("^0[oO]([0-7]+)$")
	if octalDigits then
		return tonumber(octalDigits, 8) :: number
	end

	const binaryDigits = trimmed:match("^0[bB]([01]+)$")
	if binaryDigits then
		return tonumber(binaryDigits, 2) :: number
	end

	const looksDecimal = trimmed:match("^[+-]?%d+%.?%d*$")
		or trimmed:match("^[+-]?%.%d+$")
		or trimmed:match("^[+-]?%d+%.?%d*[eE][+-]?%d+$")
		or trimmed:match("^[+-]?%.%d+[eE][+-]?%d+$")

	if looksDecimal then
		return tonumber(trimmed) :: number
	end

	return __staticProps.NAN
end

--[=[
	@private
	Whether `value` is callable: a function, or a table/userdata with `__call`.
]=]
const function isCallable(value: unknown): boolean
	if type(value) == "function" then
		return true
	end

	const kind = type(value)
	if kind == "table" or kind == "userdata" then
		const metatable = getmetatable(value :: any)
		if type(metatable) == "table" then
			return rawget(metatable, "__call") ~= nil
		end
	end

	return false
end

--[=[
	@private
	Whether `value` is a JavaScript primitive, as far as Luau can represent one.
]=]
const function isPrimitive(value: unknown): boolean
	const kind = type(value)
	return kind == "nil" or kind == "boolean" or kind == "number" or kind == "string" or Symbol.isSymbol(value)
end

--[=[
	@within __toNumber
	@param value any -- the value to coerce
	@return number -- `value` coerced the way `Number(value)` coerces it in JS

	:::caution
	An explicit `nil` argument is treated like JavaScript's `undefined`
	(→ `NaN`), never like `null` (→ `0`) — Luau's single `nil` cannot
	represent both, and `undefined` was judged the more common intent.
	The `Number` constructor itself special-cases *zero* arguments
	(`Number()`) to `0` before ever calling this function, matching JS;
	only an explicitly-passed `nil` reaches this `NaN` path.
	:::

	:::caution
	Table coercion follows JS's `ToPrimitive(value, "number")`: a callable
	`value.valueOf` is tried first, then a callable `value.toString`.
	Callable tables work, and errors raised by either method propagate.
	If no method is present, the result is `NaN` (like `Number({})` in JS);
	if methods are present but all return objects, this raises an error, as
	`ToPrimitive` does.
	:::

	:::caution
	A `Symbol` raises an error, as in JavaScript. Functions, threads, and
	`userdata` all coerce to `NaN`, since none of them has a meaningful
	numeric interpretation.
	:::
]=]
const function toNumber(value: any): number
	if value == nil then
		return __staticProps.NAN
	end

	const t = type(value)
	if t == "number" then
		return value
	end

	if t == "boolean" then
		return if value then 1 else 0
	end

	if t == "string" then
		return stringToNumber(value)
	end

	if t == "table" then
		if Symbol.isSymbol(value) then
			error("Cannot convert a Symbol value to a number", 2)
		end

		local sawToString = false
		for _, name in { "valueOf", "toString" } do
			const method = (value :: any)[name]
			if isCallable(method) then
				const result = method(value)
				if isPrimitive(result) then
					return toNumber(result)
				end
				if name == "toString" then
					sawToString = true
				end
			end
		end

		if sawToString then
			error("Cannot convert object to primitive value", 2)
		end
		return __staticProps.NAN
	end

	return __staticProps.NAN
end

return toNumber
