--!strict

--[=[
	@class isInteger

	A Luau implementation of JavaScript's
	[`Number.isInteger()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isInteger).

	Checks whether a value is a number with no fractional part.
]=]

const __staticProps = require("./__staticProps")

--[=[
	@within isInteger
	@param value any -- the value to test
	@return boolean -- `true` if `value` is a finite integer-valued number

	:::note
	Unlike plain `tonumber(value) ~= nil`-style checks, this deliberately
	does **not** coerce `value` first: a string like `"5"` returns
	`false`, exactly matching JS's `Number.isInteger("5")` being `false`
	(as opposed to the coercing global `isFinite`/`parseInt`-style
	checks some code reaches for instead).
	:::
]=]
const function isInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= __staticProps.POSITIVE_INFINITY
		and value ~= __staticProps.NEGATIVE_INFINITY
		and value == math.floor(value)
end

return isInteger
