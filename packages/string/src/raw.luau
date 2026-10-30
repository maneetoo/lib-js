--!strict

--[=[
	@class raw

	A Luau implementation of JavaScript's [`String.raw()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/raw).

	Joins a template's raw strings with substitution values.
]=]

const ECMAScript = require("../ECMAScript")

--[=[
	@within raw
	@param template { raw: { string } } -- a table whose `raw` field holds the raw string pieces
	@param ... unknown -- the substitution values, placed between the pieces
	@return string -- the pieces joined with the values

	Luau has no tagged template literals, so the caller builds the `template`
	table itself:

	```
	String.raw({ raw = { "a\\n", "b" } }, 1)  --> "a\\n1b"
	```

	:::caution
	`template.raw` must be a table, or a `TypeError` is thrown.
	:::
]=]
const function raw(template: { raw: { string } }, ...: unknown): string
	const pieces = if type(template) == "table" then template.raw else nil
	if type(pieces) ~= "table" then
		error("String.raw: template.raw must be an array")
	end

	const count = #pieces
	const parts: { string } = {}
	local length = 0
	for index = 1, count do
		length += 1
		parts[length] = ECMAScript.ToString(pieces[index])
		if index < count and index <= select("#", ...) then
			length += 1
			parts[length] = ECMAScript.ToString((select(index, ...)))
		end
	end
	return table.concat(parts)
end

return raw
