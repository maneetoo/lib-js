--!strict

--[=[
	@class abort
	@within AbortSignal

	[`AbortSignal.abort()`](https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal/abort_static):
	a signal that is already aborted.
]=]

const shared = require("./__shared")

type AbortSignal = shared.AbortSignal

--[=[
	@within AbortSignal
	@param reason any? -- the reason to store, or `nil` for the platform default
	@return AbortSignal -- a signal in the aborted state

	`AbortSignal.abort(reason?)` — the returned signal is aborted from the
	start, with `reason` as its reason, or the platform's default
	`AbortError` reason when omitted.
]=]
const function newAbortedSignal(reason: any?): AbortSignal
	const state = shared.createSignal()
	shared.abortSignal(state, reason)
	return shared.signalTable(state)
end

return newAbortedSignal
