--!strict

--[=[
	@class __toNumber
	@private

	Implements the coercion `Number(value)` performs on its argument —
	JavaScript's internal `ToNumber` abstract operation — used by the
	`Number` constructor.
]=]

const __staticProps = require "./__staticProps"

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
		return __staticProps.MAX_VALUE
	end
	if trimmed == "-Infinity" then
		return __staticProps.MIN_VALUE
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
	Table coercion follows JS's `ToPrimitive(value, "number")`: a
	callable `value.valueOf` is tried first, then a callable
	`value.toString`, each only accepted if it returns a primitive-ish
	result (`number`/`string`/`boolean`) without erroring. If neither
	works out, the result is `NaN` — matching plain objects
	(`Number({})` is `NaN` in JS too).
	:::

	:::caution
	Functions, threads, and `userdata` all coerce to `NaN`, since none
	of them have a meaningful numeric interpretation and JS has no
	equivalent types to compare against.
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
		const valueOfFn = (value :: any).valueOf
		if type(valueOfFn) == "function" then
			const ok, result = pcall(valueOfFn, value)
			if ok and (type(result) == "number" or type(result) == "string" or type(result) == "boolean") then
				return toNumber(result)
			end
		end

		const toStringFn = (value :: any).toString
		if type(toStringFn) == "function" then
			const ok, result = pcall(toStringFn, value)
			if ok and type(result) == "string" then
				return stringToNumber(result)
			end
		end

		return __staticProps.NAN
	end

	return __staticProps.NAN
end

return toNumber
