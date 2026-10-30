--!strict

--[=[
	@class timeout
	@within AbortSignal

	[`AbortSignal.timeout()`](https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal/timeout_static):
	a signal that aborts after a delay.
]=]

const Error = require("../Error")
const Timers = require("../Timers")
const shared = require("./__shared")

type AbortSignal = shared.AbortSignal

--[=[
	@within AbortSignal
	@param ms number -- milliseconds to wait before aborting
	@return AbortSignal -- a signal that aborts with a `TimeoutError` reason

	`AbortSignal.timeout(ms)` — after `ms` milliseconds the signal aborts
	with a `TimeoutError`-named `Error` (message `"signal timed out"`),
	letting consumers distinguish timeouts from user cancellation by
	`reason.name`, exactly as on the platform.

	:::note
	The delay runs through this library's `Timers` scheduler, so it respects
	`Timers.setClock` / `setSleep` and fires on `Timers.step` / `run`. The
	timer cannot be cancelled: the signal is single-use.
	:::
]=]
const function newTimeoutSignal(ms: number): AbortSignal
	if type(ms) ~= "number" then
		error(Error.new("AbortSignal.timeout: ms must be a number"), 2)
	end
	const state = shared.createSignal()
	const signal = shared.signalTable(state)
	Timers.setTimeout(function()
		shared.abortSignal(state, shared.defaultTimeoutReason())
	end, ms)
	return signal
end

return newTimeoutSignal
