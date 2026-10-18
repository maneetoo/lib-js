--!strict

--[=[
	@class setTimeout
	@within Timers

	Calls a function once after a delay. A JavaScript
	[`setTimeout()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/setTimeout)
	counterpart. Returns a positive integer id for `clearTimeout`.
]=]

const Number = require "../Number"
const TypeError = require "../Error" .TypeError
const __scheduler = require "./__scheduler"

--[=[
	@within setTimeout
	@param callback () -> () -- the function to call
	@param delay number? -- milliseconds. `NaN`, values below 1, and values above 2147483647 use 1.
	@param ... any -- passed to `callback`
	@return number -- the timer id
	@error TypeError -- `callback` is not a function
]=]
const function setTimeout(callback: (...any) -> (), delay: number?, ...: any): number
	if type(callback) ~= "function" then
		error(TypeError.new("The \"callback\" argument must be of type function"), 2)
	end
	const ms: number = __scheduler.normalizeDelay(Number(delay))
	return __scheduler.schedule(callback, ms, table.pack(...), false)
end

return setTimeout
