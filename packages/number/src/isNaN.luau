--!strict

--[=[
	@class isNaN

	A Luau implementation of JavaScript's
	[`Number.isNaN()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isNaN).

	Checks whether a value is the number `NaN`.
]=]

--[=[
	@within isNaN
	@param value any -- the value to test
	@return boolean -- `true` if `value` is a number and is `NaN`

	:::note
	As with `isFinite`, this deliberately does not coerce `value`
	first: a non-numeric value such as `"hello"` or `nil` returns
	`false`, mirroring how JS's `Number.isNaN("hello")` is `false` —
	unlike the global `isNaN` function, which coerces its argument
	(`isNaN("hello")` is `true` in JS, because `"hello"` coerces to
	`NaN`).
	:::

	The check itself relies on the one universal property of `NaN`: it
	is the only value that is never equal to itself, under any
	numeric comparison.
]=]
const function isNaN(value: any): boolean
	return type(value) == "number" and value ~= value
end

return isNaN
