--!strict

--[=[
	@class any

	[`AbortSignal.any()`](https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal/any_static):
	a signal that follows the first of several sources.
]=]

const Error = require("../Error")
const shared = require("./__shared")

type AbortSignal = shared.AbortSignal

--[=[
	@within any
	@param signals { AbortSignal } -- the source signals to combine
	@return AbortSignal -- a signal that aborts when the first source does

	`AbortSignal.any(signals)` — the combined signal starts live (unless a
	source is already aborted, in which case that reason is adopted at
	once), and aborts with the reason of the **first** source to abort.
	Once one source fires, the listeners on the other sources are removed,
	so the combined signal settles exactly once.
]=]
const function newAnySignal(signals: { AbortSignal }): AbortSignal
	if type(signals) ~= "table" then
		error(Error.new("AbortSignal.any: argument must be an array of signals"), 2)
	end
	const state = shared.createSignal()
	const pending: { AbortSignal } = {}
	for _, source in signals do
		if type(source) ~= "table" then
			error(Error.new("AbortSignal.any: argument must be an array of signals"), 2)
		end
		if source.aborted then
			-- First source already aborted: adopt it and stop.
			shared.abortSignal(state, source.reason)
			break
		end
		table.insert(pending, source)
	end
	if not state._aborted then
		-- The first source to abort decides; the rest of the listeners are
		-- removed so the combined signal settles once.
		const wrapped: { AbortListener } = {}
		for index, source in pending do
			wrapped[index] = function()
				if not state._aborted then
					for _, other in wrapped do
						source:removeEventListener("abort", other)
					end
					shared.abortSignal(state, source.reason)
				end
			end
			source:addEventListener("abort", wrapped[index])
		end
	end
	return shared.signalTable(state)
end

return newAnySignal
