--!strict

--[=[
	@class setInterval
	@within Timers

	Calls a function repeatedly, every `delay` milliseconds. A JavaScript
	[`setInterval()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/setInterval)
	counterpart. Stop it with `clearInterval`. Returns a positive integer id.
]=]

const Number = require "../Number"
const TypeError = require "../Error" .TypeError
const __scheduler = require "./__scheduler"

--[=[
	@within setInterval
	@param callback () -> () -- the function to call
	@param delay number? -- milliseconds between calls. `NaN`, values below 1, and values above 2147483647 use 1.
	@param ... any -- passed to `callback` on each call
	@return number -- the interval id
	@error TypeError -- `callback` is not a function
]=]
const function setInterval(callback: (...any) -> (), delay: number?, ...: any): number
	if type(callback) ~= "function" then
		error(TypeError.new("The \"callback\" argument must be of type function"), 2)
	end
	const ms: number = __scheduler.normalizeDelay(Number(delay))
	return __scheduler.schedule(callback, ms, table.pack(...), true)
end

return setInterval
