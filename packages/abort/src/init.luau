--!strict

--[=[
	@class abort

	Luau implementations of the Web platform's
	[`AbortController`](https://developer.mozilla.org/en-US/docs/Web/API/AbortController)
	and
	[`AbortSignal`](https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal).

	An `AbortSignal` is a one-way switch: `aborted` starts `false`, and the
	first `abort()` flips it, stores a `reason`, and fires the `abort`
	listeners. After that the signal is settled — later `abort()` calls are
	no-ops (the first reason wins), and listeners registered after the abort
	never fire.

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
	There is no real `EventTarget` base in the Web sense here; the signal
	provides `addEventListener`/`removeEventListener` for the `"abort"` event
	directly (the events package is deliberately not a dependency — the
	signal is self-contained).
	:::

	:::caution
	JavaScript's default reason is an `AbortError` `DOMException`. There is
	no `DOMException` in this library, so the default (and
	`AbortSignal.timeout`'s reason) is an `Error` whose `name` is set to
	`"AbortError"` / `"TimeoutError"` with the platform's messages — the
	shape every consumer checks (`reason.name`) still matches.
	:::

	:::note
	`AbortSignal.timeout` uses this library's `Timers` scheduler, so it
	respects `Timers.setClock`/`setSleep` — a virtual clock makes it
	deterministic in tests, and `Timers.step`/`run` drive the timeout.
	:::
]=]

const Error = require("./Error")
const Timers = require("./Timers")

type AbortListener = (event: any) -> ()

--[=[
	@within abort
	@type AbortSignal = { read aborted: boolean, read reason: any, addEventListener: ..., removeEventListener: ..., throwIfAborted: ... }

	A signal whose `aborted`/`reason` are readable, with listener support
	for the `"abort"` event and `throwIfAborted`.
]=]
export type AbortSignal = {
	read aborted: boolean,
	read reason: any,
	addEventListener: (self: AbortSignal, type: string, listener: AbortListener) -> (),
	removeEventListener: (self: AbortSignal, type: string, listener: AbortListener) -> (),
	throwIfAborted: (self: AbortSignal) -> (),
}

type SignalState = {
	_aborted: boolean,
	_reason: any,
	_listeners: { AbortListener },
}

local function defaultAbortReason(): any
	const err = Error.new("signal is aborted without reason")
	local asError = err :: any
	asError.name = "AbortError"
	return err
end

local function defaultTimeoutReason(): any
	const err = Error.new("signal timed out")
	local asError = err :: any
	asError.name = "TimeoutError"
	return err
end

-- Shared signal machinery: create, read, listen, abort.
local function createSignal(): SignalState
	return { _aborted = false, _reason = nil, _listeners = {} }
end

local function abortSignal(state: SignalState, reason: any)
	if state._aborted then
		-- First abort wins; everything after is a no-op, even a new reason.
		return
	end
	state._aborted = true
	state._reason = if reason == nil then defaultAbortReason() else reason
	-- Snapshot: the abort event fires once; a listener added by another
	-- listener during the dispatch does not run for this abort.
	const snapshot = table.clone(state._listeners)
	state._listeners = {}
	for _, listener in snapshot do
		listener({ type = "abort" })
	end
end

local function signalTable(state: SignalState): AbortSignal
	return setmetatable(
		{} :: any,
		{
			__index = function(_self: any, key: any): any
				if key == "aborted" then
					return state._aborted
				elseif key == "reason" then
					return if state._aborted then state._reason else nil
				elseif key == "addEventListener" then
					return function(_self: any, eventType: string, listener: AbortListener)
						if eventType ~= "abort" then
							-- Other event types simply have no dispatch path; like
							-- the platform, registering one is allowed and inert.
							return
						end
						if type(listener) ~= "function" then
							error(Error.new("AbortSignal.addEventListener: listener must be a function"), 2)
						end
						if state._aborted then
							-- Listeners added after the abort never fire.
							return
						end
						for _, existing in state._listeners do
							if existing == listener then
								return
							end
						end
						table.insert(state._listeners, listener)
					end
				elseif key == "removeEventListener" then
					return function(_self: any, _eventType: string, listener: AbortListener)
						for index, existing in state._listeners do
							if existing == listener then
								table.remove(state._listeners, index)
								return
							end
						end
					end
				elseif key == "throwIfAborted" then
					return function(_self: any)
						if state._aborted then
							-- Throws the reason as-is, like the platform.
							error(state._reason, 2)
						end
					end
				end
				return nil
			end,
		} :: any
	) :: AbortSignal
end

--[=[
	@within abort
	@type AbortController = { read signal: AbortSignal, abort: ... }

	One controller paired with one signal.
]=]
export type AbortController = {
	read signal: AbortSignal,
	abort: (self: AbortController, reason: any?) -> (),
}

type ControllerState = { _state: SignalState, _signal: AbortSignal }

--[=[
	@within abort
	@return AbortController -- a new controller with a fresh signal

	`AbortController.new()` (JS: `new AbortController()`).
]=]
local function newController(): AbortController
	const state = createSignal()
	const controller: ControllerState = { _state = state, _signal = signalTable(state) }
	return setmetatable(
		controller :: any,
		{
			__index = function(self: any, key: any): any
				if key == "signal" then
					return (self :: ControllerState)._signal
				elseif key == "abort" then
					return function(_self: any, reason: any?)
						abortSignal((self :: ControllerState)._state, reason)
					end
				end
				return nil
			end,
		} :: any
	) :: AbortController
end

local AbortController = table.freeze({ new = newController }) :: any

local function newAbortedSignal(reason: any?): AbortSignal
	const state = createSignal()
	abortSignal(state, reason)
	return signalTable(state)
end

local function newTimeoutSignal(ms: number): AbortSignal
	if type(ms) ~= "number" then
		error(Error.new("AbortSignal.timeout: ms must be a number"), 2)
	end
	const state = createSignal()
	const signal = signalTable(state)
	Timers.setTimeout(function()
		abortSignal(state, defaultTimeoutReason())
	end, ms)
	return signal
end

local function newAnySignal(signals: { AbortSignal }): AbortSignal
	if type(signals) ~= "table" then
		error(Error.new("AbortSignal.any: argument must be an array of signals"), 2)
	end
	const state = createSignal()
	const signal = signalTable(state)
	local pending: { { any } } = {}
	for _, source in signals do
		if type(source) ~= "table" then
			error(Error.new("AbortSignal.any: argument must be an array of signals"), 2)
		end
		if source.aborted then
			-- First source already aborted: adopt it and stop.
			abortSignal(state, source.reason)
			break
		end
		table.insert(pending, { source })
	end
	if not state._aborted then
		-- The first source to abort decides; the rest of the listeners are
		-- removed so the combined signal settles once.
		local wrapped = {}
		for index, entry in pending do
			local source = entry[1]
			wrapped[index] = function()
				if not state._aborted then
					for _, other in wrapped do
						(source :: any).removeEventListener(source, "abort", other)
					end
					abortSignal(state, (source :: AbortSignal).reason)
				end
			end
			source:addEventListener("abort", wrapped[index])
		end
	end
	return signal
end

local AbortSignal = table.freeze({
	abort = newAbortedSignal,
	timeout = newTimeoutSignal,
	any = newAnySignal,
}) :: any

return table.freeze({
	AbortController = AbortController,
	AbortSignal = AbortSignal,
})
