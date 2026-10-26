--!strict

--[=[
	@class isRawJSON

	A Luau implementation of JavaScript's
	[`JSON.isRawJSON()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/isRawJSON).

	Tests whether a value is an object made by `JSON.rawJSON`.
]=]

const __raw = require("./__raw")

--[=[
	@within isRawJSON
	@param value any -- the value to test
	@return boolean -- `true` if `value` was returned by `JSON.rawJSON`

	A plain table with a `rawJSON` field is not raw JSON. Only the objects that
	`rawJSON` makes count.
]=]
const function isRawJSON(value: any): boolean
	return __raw.isRaw(value)
end

return isRawJSON
