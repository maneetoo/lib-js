--!strict

--[=[
	@class AbortController
	@within AbortController

	Web platform's
	[`AbortController`](https://developer.mozilla.org/en-US/docs/Web/API/AbortController):
	one controller paired with one signal, whose `abort()` settles it.
]=]

const shared = require("./__shared")

type AbortController = shared.AbortController

--[=[
	@within AbortController
	@return AbortController -- a new controller with a fresh signal

	`AbortController.new()` (JS: `new AbortController()`).

	The controller exposes:

	- `signal` — its `AbortSignal`, created eagerly and shared for the
	  controller's lifetime
	- `abort(reason?)` — settles the signal with `reason` (defaulting to the
	  platform's `AbortError` reason); the first call wins, later calls are
	  no-ops
]=]
const function newController(): AbortController
	const state = shared.createSignal()
	const signal = shared.signalTable(state)
	return setmetatable(
		{} :: any,
		{
			__index = function(_self: any, key: any): any
				if key == "signal" then
					return signal
				elseif key == "abort" then
					return function(_self2: any, reason: any?)
						shared.abortSignal(state, reason)
					end
				end
				return nil
			end,
		} :: any
	) :: AbortController
end

return table.freeze({ new = newController })
