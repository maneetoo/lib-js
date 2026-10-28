--!strict

--[=[
	@class JSON

	A Luau port of JavaScript's
	[`JSON`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON)
	namespace object: `parse` turns JSON text into a value, and `stringify` turns
	a value into JSON text.

	```lua
	local JSON = require(path.to.JSON)

	local value = JSON.parse('{"a":[1,2,{"b":true}]}')
	print(JSON.stringify(value)) -- {"a":[1,2,{"b":true}]}
	print(JSON.stringify({ 1, 2 }, nil, 2))
	```

	:::note
	`JSON` is not a constructor. It is a plain namespace table, and calling it
	is an error. Its `[Symbol.toStringTag]` is `"JSON"`, so
	`Object.prototype.toString` reports `"[object JSON]"`.
	:::

	:::note
	The module table is frozen with `table.freeze`. No members can be added,
	removed, or reassigned.
	:::

	:::caution
	This library has one `nil` for `undefined` and `null`. So `null` parses to
	`nil`, and `nil` serializes as `undefined`. See `parse` and `stringify` for
	the other caveats: empty tables, key order, and holes in arrays.
	:::
]=]

const Symbol = require("./Symbol")
const isRawJSON = require("@self/isRawJSON")
const parse = require("@self/parse")
const rawJSON = require("@self/rawJSON")
const stringify = require("@self/stringify")

const JSON = table.freeze({
	parse = parse,
	stringify = stringify,
	rawJSON = rawJSON,
	isRawJSON = isRawJSON,
	[Symbol.toStringTag] = "JSON",
})

return JSON
