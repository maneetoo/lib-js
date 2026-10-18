--!strict

--[=[
	@class clearInterval
	@within Timers

	Stops an interval made by `setInterval`. A JavaScript
	[`clearInterval()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/clearInterval)
	counterpart. An unknown id, or `nil`, does nothing. It may be called from
	inside the interval's own callback.
]=]

const __scheduler = require "./__scheduler"

--[=[
	@within clearInterval
	@param id number? -- an id returned by `setInterval`
]=]
const function clearInterval(id: number?)
	if id ~= nil then
		__scheduler.cancel(id)
	end
end

return clearInterval
