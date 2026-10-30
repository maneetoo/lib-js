--!strict

--[=[
	@class abort
	@within AbortSignal

	Luau implementations of the Web platform's
	[`AbortController`](https://developer.mozilla.org/en-US/docs/Web/API/AbortController)
	and
	[`AbortSignal`](https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal).

	An `AbortSignal` is a one-way switch: `aborted` starts `false`, and the
	first `abort()` flips it, stores a `reason`, and fires the `abort`
	listeners. After that the signal is settled — later `abort()` calls are
	no-ops (the first reason wins), and listeners registered after the
	abort never fire.

	```lua
	local abort = require(path.to.abort)

	local controller = abort.AbortController.new()
	controller.signal:addEventListener("abort", function()
		print("aborted:", controller.signal.reason.message)
	end)
	controller:abort() -- prints: aborted: signal is aborted without reason
	```

	Statics on `AbortSignal`:

	- `AbortSignal.abort(reason?)` — a signal already aborted
	- `AbortSignal.timeout(ms)` — aborts with a `TimeoutError`-named reason
	  after `ms`, through the `Timers` scheduler
	- `AbortSignal.any(signals)` — aborts with the first source to abort

	:::caution
	JavaScript's default reason is an `AbortError` `DOMException`. There is
	no `DOMException` in this library, so the default (and
	`AbortSignal.timeout`'s reason) is an `Error` whose `name` is set to
	`"AbortError"` / `"TimeoutError"` with the platform's messages — the
	shape every consumer checks (`reason.name`) still matches.
	:::

	:::caution
	There is no real `EventTarget` base in the Web sense here; the signal
	provides `addEventListener`/`removeEventListener` for the `"abort"` event
	directly (the events package is deliberately not a dependency — the
	signal is self-contained).
	:::

	:::note
	`AbortSignal.timeout` uses this library's `Timers` scheduler, so it
	respects `Timers.setClock`/`setSleep` — a virtual clock makes it
	deterministic in tests, and `Timers.step`/`run` drive the timeout.
	:::
]=]

const shared = require("@self/__shared")

export type AbortSignal = shared.AbortSignal
export type AbortController = shared.AbortController
export type AbortListener = shared.AbortListener
export type AbortSignalStatic = shared.AbortSignalStatic
export type AbortControllerStatic = shared.AbortControllerStatic

const AbortController = {
	new = require("@self/AbortController").new,
} :: AbortControllerStatic

const AbortSignal = {} :: AbortSignalStatic

-- The statics, wired in place (a frozen literal cannot reference its own
-- module's sibling fields, so assign before freezing).
const statics = AbortSignal
statics.abort = require("@self/abort")
statics.timeout = require("@self/timeout")
statics.any = require("@self/any")

table.freeze(AbortSignal)
table.freeze(AbortController)

return table.freeze({
	AbortController = AbortController,
	AbortSignal = AbortSignal,
})
