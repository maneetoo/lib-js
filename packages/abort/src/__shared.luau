--!strict

--[=[
	@class __shared
	@private

	Internal signal machinery shared by the `abort` modules: the exported
	instance types, the signal state, the abort transition, the
	event-target surface exposed on every signal, and the default reasons.
	Not part of the public API; the types are, re-exported through the
	package's `init`.

	:::note
	Keep helpers small. Logic used by a single method lives in that method's file.
	:::
]=]

const Error = require("../Error")

--[=[
	@within __shared
	@type AbortListener = (event: any) -> ()

	A listener for the `"abort"` event. The argument is a minimal event
	table: `{ type = "abort" }`.
]=]
export type AbortListener = (event: any) -> ()

--[=[
	@within __shared
	@type AbortSignal = { read aborted: boolean, read reason: any, addEventListener: ..., removeEventListener: ..., throwIfAborted: ... }

	A signal: `aborted` and `reason` are readable, and the methods
	register, remove, and act on `"abort"` listeners. Constructed by
	`AbortController.new()` and the `AbortSignal` statics; there is no
	direct `AbortSignal.new` (the platform has none either).
]=]
export type AbortSignal = {
	read aborted: boolean,
	read reason: any,
	addEventListener: (self: AbortSignal, type: string, listener: AbortListener) -> (),
	removeEventListener: (self: AbortSignal, type: string, listener: AbortListener) -> (),
	throwIfAborted: (self: AbortSignal) -> (),
}

--[=[
	@within __shared
	@type AbortController = { read signal: AbortSignal, abort: (self: AbortController, reason: any?) -> () }

	One controller paired with one signal. `signal` is created eagerly and
	shared for the controller's lifetime; `abort` settles it.
]=]
export type AbortController = {
	read signal: AbortSignal,
	abort: (self: AbortController, reason: any?) -> (),
}

--[=[
	@within __shared
	@type AbortSignalStatic = { abort: ..., timeout: ..., any: ... }

	The `AbortSignal` constructor table: the statics `abort`, `timeout`,
	and `any`.
]=]
export type AbortSignalStatic = {
	abort: (reason: any?) -> AbortSignal,
	timeout: (ms: number) -> AbortSignal,
	any: (signals: { AbortSignal }) -> AbortSignal,
}

--[=[
	@within __shared
	@type AbortControllerStatic = { new: () -> AbortController }

	The `AbortController` constructor table.
]=]
export type AbortControllerStatic = {
	new: () -> AbortController,
}

--[=[
	@within __shared
	@type SignalState = { _aborted: boolean, _reason: any, _listeners: { AbortListener } }

	The mutable state behind one signal. `_aborted` flips once; `_reason`
	is written with it; `_listeners` empties after the abort event fires.
]=]
export type SignalState = {
	_aborted: boolean,
	_reason: any,
	_listeners: { AbortListener },
}

--[=[
	@within __shared
	@private
	@return any

	The default reason when `abort()` gets none: an `AbortError`-named
	`Error` with the platform's message. JavaScript uses a `DOMException`;
	there is none here, but `reason.name` — what consumers check — matches.
]=]
const function defaultAbortReason(): any
	const err = Error.new("signal is aborted without reason")
	const asError = err :: any
	asError.name = "AbortError"
	return err
end

--[=[
	@within __shared
	@private
	@return any

	`AbortSignal.timeout`'s reason: a `TimeoutError`-named `Error` with the
	platform's message.
]=]
const function defaultTimeoutReason(): any
	const err = Error.new("signal timed out")
	const asError = err :: any
	asError.name = "TimeoutError"
	return err
end

--[=[
	@within __shared
	@private
	@return SignalState

	Builds a fresh, live signal state.
]=]
const function createSignal(): SignalState
	return { _aborted = false, _reason = nil, _listeners = {} }
end

--[=[
	@within __shared
	@private
	@param state SignalState -- the state to settle
	@param reason any -- the reason to store, or `nil` for the platform default

	Flips `state` to aborted (the first call only), stores the reason, and
	fires the `abort` listeners once from a snapshot — a listener added by
	another listener during the dispatch does not run for this abort.
]=]
const function abortSignal(state: SignalState, reason: any)
	if state._aborted then
		-- First abort wins; everything after is a no-op, even a new reason.
		return
	end
	state._aborted = true
	state._reason = if reason == nil then defaultAbortReason() else reason
	const snapshot = table.clone(state._listeners)
	state._listeners = {}
	for _, listener in snapshot do
		listener({ type = "abort" })
	end
end

--[=[
	@within __shared
	@private
	@param state SignalState -- the state to surface
	@return AbortSignal

	The readable signal surface for `state`: `aborted` and `reason` through
	`__index`, plus `addEventListener`, `removeEventListener`, and
	`throwIfAborted` as closures over the state.
]=]
const function signalTable(state: SignalState): AbortSignal
	return setmetatable(
		{} :: any,
		{
			__index = function(_self: any, key: any): any
				if key == "aborted" then
					return state._aborted
				elseif key == "reason" then
					return if state._aborted then state._reason else nil
				elseif key == "addEventListener" then
					return function(_self2: any, eventType: string, listener: AbortListener)
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
					return function(_self2: any, _eventType: string, listener: AbortListener)
						for index, existing in state._listeners do
							if existing == listener then
								table.remove(state._listeners, index)
								return
							end
						end
					end
				elseif key == "throwIfAborted" then
					return function(_self2: any)
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

return table.freeze({
	defaultAbortReason = defaultAbortReason,
	defaultTimeoutReason = defaultTimeoutReason,
	createSignal = createSignal,
	abortSignal = abortSignal,
	signalTable = signalTable,
})
