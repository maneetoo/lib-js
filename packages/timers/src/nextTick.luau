--!strict

--[=[
	@class nextTick
	@within Timers

	Calls a function after the current operation, before any immediate or timer.
	A Node.js
	[`process.nextTick()`](https://nodejs.org/api/process.html#processnexttickcallback-args)
	counterpart. Returns nothing, as in Node.js, so a tick cannot be cancelled.

	The ticks run in the order they were queued, at the start of each turn and
	again after each immediate and each timer. A tick that queues another tick
	runs it in the same drain, before the turn goes on, so a tick that always
	queues another one keeps the loop from reaching the timers.

	:::caution
	The `Promise` microtask queue has its own scheduler, and `step` does not
	drain it. `nextTick` is ordered before immediates and timers, but not before
	`Promise` reactions or `queueMicrotask` callbacks.
	:::
]=]

const TypeError = require("../Error").TypeError
const __scheduler = require("./__scheduler")

--[=[
	@within nextTick
	@param callback () -> () -- the function to call
	@param ... any -- passed to `callback`
	@error TypeError -- `callback` is not a function
]=]
const function nextTick(callback: (...any) -> (), ...: any)
	if type(callback) ~= "function" then
		error(TypeError.new('The "callback" argument must be of type function'), 2)
	end
	__scheduler.tick(callback, table.pack(...))
end

return nextTick
