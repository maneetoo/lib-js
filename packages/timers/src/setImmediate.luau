--!strict

--[=[
	@class setImmediate
	@within Timers

	Calls a function on the next turn of the loop, before timers that are due
	later. A Node.js
	[`setImmediate()`](https://nodejs.org/api/timers.html#setimmediatecallback-args)
	counterpart. Returns a positive integer id for `clearImmediate`.
]=]

const TypeError = require("../Error").TypeError
const __scheduler = require("./__scheduler")

--[=[
	@within setImmediate
	@param callback () -> () -- the function to call
	@param ... any -- passed to `callback`
	@return number -- the immediate id
	@error TypeError -- `callback` is not a function
]=]
const function setImmediate(callback: (...any) -> (), ...: any): number
	if type(callback) ~= "function" then
		error(TypeError.new('The "callback" argument must be of type function'), 2)
	end
	return __scheduler.immediate(callback, table.pack(...))
end

return setImmediate
