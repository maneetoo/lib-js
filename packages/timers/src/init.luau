--!strict

--[=[
	@class Timers
	@within Timers

	The timer functions of JavaScript's host environment:
	[`setTimeout`](https://developer.mozilla.org/en-US/docs/Web/API/Window/setTimeout),
	[`clearTimeout`](https://developer.mozilla.org/en-US/docs/Web/API/Window/clearTimeout),
	[`setInterval`](https://developer.mozilla.org/en-US/docs/Web/API/Window/setInterval),
	[`clearInterval`](https://developer.mozilla.org/en-US/docs/Web/API/Window/clearInterval),
	and Node.js's
	[`setImmediate`](https://nodejs.org/api/timers.html#setimmediatecallback-args)
	and
	[`clearImmediate`](https://nodejs.org/api/timers.html#clearimmediateimmediate).

	Luau has no event loop, so nothing runs by itself. Call `step()` from your
	loop to run one turn, or `run()` to run until nothing is pending. `run`,
	`step`, `setClock` and `setSleep` are not in JavaScript. Each timer is a
	coroutine, so a callback can yield or fail without stopping the scheduler.

	:::caution
	The default clock is `os.clock`, which measures CPU time. It does not move
	while the host waits, so timers never fire in a host that only calls `step`
	between waits. A host that waits must call `setClock` with a wall clock in
	milliseconds. Use the same clock for every call.
	:::

	:::caution
	Without `setSleep`, `run` waits by spinning on the clock, which keeps one CPU
	busy until the next timer. A long timer keeps it busy for that whole time.
	Call `setSleep` with a function that waits for the given seconds.
	:::

	:::caution
	Timer ids are numbers, not the `Timeout` objects Node.js returns, and
	`clearTimeout` accepts only numbers.
	:::
]=]

const __scheduler = require("@self/__scheduler")

return table.freeze({
	setTimeout = require("@self/setTimeout"),
	clearTimeout = require("@self/clearTimeout"),
	setInterval = require("@self/setInterval"),
	clearInterval = require("@self/clearInterval"),
	setImmediate = require("@self/setImmediate"),
	clearImmediate = require("@self/clearImmediate"),
	step = __scheduler.step,
	run = __scheduler.run,
	setClock = __scheduler.setClock,
	setSleep = __scheduler.setSleep,
})
