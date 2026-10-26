--!strict

--[=[
	@class clearTimeout
	@within Timers

	Cancels a timer made by `setTimeout`. A JavaScript
	[`clearTimeout()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/clearTimeout)
	counterpart. An unknown id, or `nil`, does nothing.
]=]

const __scheduler = require("./__scheduler")

--[=[
	@within clearTimeout
	@param id number? -- an id returned by `setTimeout`
]=]
const function clearTimeout(id: number?)
	if id ~= nil then
		__scheduler.cancel(id)
	end
end

return clearTimeout
