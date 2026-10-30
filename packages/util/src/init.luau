--!strict

--[=[
	@class util

	A Luau implementation of Node.js's
	[`util`](https://nodejs.org/api/util.html) module: `format` (printf-style
	formatting) and `inspect` (debugging strings for any value).

	```lua
	local util = require(path.to.util)

	print(util.format("%s=%d", "answer", 42)) -- answer=42
	print(util.inspect({ list = { 1, 2, 3 } })) -- { list: [ 1, 2, 3 ] }
	```
]=]

return table.freeze({
	format = require("@self/format"),
	inspect = require("@self/inspect"),
})
