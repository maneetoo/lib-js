--!strict

--[=[
	@class clearImmediate
	@within Timers

	Cancels an immediate made by `setImmediate` before it runs. A Node.js
	[`clearImmediate()`](https://nodejs.org/api/timers.html#clearimmediateimmediate)
	counterpart. An unknown id, or `nil`, does nothing.
]=]

const scheduler = require "./__scheduler"

--[=[
	@within clearImmediate
	@param id number? -- an id returned by `setImmediate`
]=]
const function clearImmediate(id: number?)
	if id ~= nil then
		scheduler.cancelImmediate(id)
	end
end

return clearImmediate
