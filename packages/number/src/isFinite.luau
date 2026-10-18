--!strict

--[=[
	@class isFinite

	A Luau implementation of JavaScript's
	[`Number.isFinite()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isFinite).

	Checks whether a value is a finite number.
]=]

const __staticProps = require "./__staticProps"

--[=[
	@within isFinite
	@param value any -- the value to test
	@return boolean -- `true` if `value` is a number that is neither `NaN` nor infinite

	:::note
	This mirrors JavaScript's `Number.isFinite`, which — unlike the
	global `isFinite` function JS also provides — does **not** coerce
	its argument first: `Number.isFinite("5")` is `false` in JS, because
	`"5"` is never coerced to the number `5` before the check. This
	function behaves the same way: a non-`number` value always returns
	`false`, with no attempt to `tonumber()` it first.
	:::
]=]
const function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= __staticProps.POSITIVE_INFINITY and value ~= __staticProps.NEGATIVE_INFINITY
end

return isFinite
