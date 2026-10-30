--!strict

--[=[
	@class queueMicrotask

	A Luau implementation of JavaScript's
	[`queueMicrotask()`](https://developer.mozilla.org/en-US/docs/Web/API/Window/queueMicrotask).

	Queues a callback to run as a **microtask**: after the current synchronous
	code finishes, before the next timer or event — and FIFO-interleaved with
	`Promise` reaction callbacks, because both share one queue.

	```lua
	local queueMicrotask = require(path.to.queueMicrotask)

	Promise.__setScheduler(task.defer) -- once, so jobs drain automatically

	queueMicrotask(function()
		print("runs after the current code, before any timer")
	end)
	```
]=]

const TypeError = require("./Error").TypeError
const Promise = require("./Promise")

--[=[
	@within queueMicrotask
	@param callback () -> () -- the function to run as a microtask
	@return nil -- nothing, like JavaScript

	Queues `callback` on the same microtask queue `Promise` reactions use
	(the queue drained by `Promise.__runJobs` / `Promise.__setScheduler`),
	so ordering matches JavaScript: a `queueMicrotask` callback and a
	`then` callback queued after it run in the order they were queued, and
	both run before any `setTimeout` callback.

	As in JavaScript, `callback` runs with no result and no error handling
	around it: an error it throws is not caught here and propagates out of
	whatever drains the queue. A non-function `callback` throws a
	`TypeError` immediately, synchronously.

	:::note
	JavaScript itself specifies `queueMicrotask` as the fallback pattern
	`Promise.resolve().then(callback)`, which is exactly what this does —
	with the one visible difference that the resulting promise is kept
	internal, so an uncaught throw is not additionally reported as an
	unhandled promise rejection.
	:::
]=]
const function queueMicrotask(callback: () -> ())
	if type(callback) ~= "function" then
		error(TypeError.new("queueMicrotask: callback is not a function"), 2)
	end

	-- A resolved promise's reaction is a microtask on the shared queue. The
	-- derived promise is discarded: the callback's return value and any error
	-- it throws belong to the microtask itself, not to a promise chain.
	const settled = Promise.resolve(nil)
	settled["then"](settled, function()
		callback()
	end)
end

return queueMicrotask
