--!strict

--[=[
	@class EventEmitter
	@within EventEmitter

	Node.js
	[`events`](https://nodejs.org/api/events.html) `EventEmitter`
	constructor table: `EventEmitter.new()`.
]=]

const TypeError = require("../Error")

--[=[
	@within EventEmitter
	@type EventEmitterListener = (...any) -> ()

	A listener registered on an emitter. It receives whatever arguments
	`emit` passes, like Node's listeners.
]=]
export type EventEmitterListener = (...any) -> ()

--[=[
	@within EventEmitter
	@type EventEmitter = { on: ..., addListener: ..., once: ..., prependListener: ..., off: ..., removeListener: ..., emit: ..., eventNames: ..., listenerCount: ... }

	Node's emitter: `on`/`addListener`/`once`/`prependListener` for
	registration, `off`/`removeListener` for removal, `emit` for
	synchronous ordered dispatch, `eventNames`/`listenerCount` for
	introspection.
]=]
export type EventEmitter = {
	on: (self: EventEmitter, eventName: string, listener: EventEmitterListener) -> EventEmitter,
	addListener: (self: EventEmitter, eventName: string, listener: EventEmitterListener) -> EventEmitter,
	once: (self: EventEmitter, eventName: string, listener: EventEmitterListener) -> EventEmitter,
	prependListener: (self: EventEmitter, eventName: string, listener: EventEmitterListener) -> EventEmitter,
	off: (self: EventEmitter, eventName: string, listener: EventEmitterListener) -> EventEmitter,
	removeListener: (self: EventEmitter, eventName: string, listener: EventEmitterListener) -> EventEmitter,
	emit: (self: EventEmitter, eventName: string, ...any) -> boolean,
	eventNames: (self: EventEmitter) -> { string },
	listenerCount: (self: EventEmitter, eventName: string) -> number,
}

-- One registration: the original listener plus its `once` flag.
type Wrapped = { original: EventEmitterListener, once: boolean }

type EventEmitterState = {
	_listeners: { [string]: { Wrapped } },
}

const function requireEventName(eventName: string)
	if type(eventName) ~= "string" then
		error(TypeError.new("EventEmitter: eventName must be a string"), 3)
	end
end

const function requireListener(listener: EventEmitterListener)
	if type(listener) ~= "function" then
		error(TypeError.new("EventEmitter: listener must be a function"), 3)
	end
end

--[=[
	@within EventEmitter
	@return EventEmitter -- a new, empty emitter

	`EventEmitter.new()` (JS: `new EventEmitter()`). The emitter exposes:

	- `on` / `addListener` — register a listener; **Node's rule**: duplicate
	  registrations each fire (no dedup)
	- `once` — removed before its first invocation, at most one call
	- `prependListener` — registers at the front of the listener queue
	- `off` / `removeListener` — remove at most **one** instance (the most
	  recently added); returns the emitter for chaining
	- `emit(eventName, ...)` — runs listeners synchronously in
	  registration order; returns `true` iff any ran. A removal during
	  `emit` does not stop listeners already scheduled for this call. An
	  `emit("error", ...)` with no listeners re-throws the reason
	- `eventNames` / `listenerCount` — introspection

	:::caution
	Node's unhandled-`error`-event process crash cannot be reproduced
	portably; an `emit("error", ...)` with no listeners re-throws the
	reason out of `emit` instead (the closest portable behaviour, and what
	Node itself does when the listener exists). Listener errors likewise
	propagate out of `emit` rather than being routed to an `error` event.
	:::

	:::note
	`newListener`/`removeListener` meta-events and the max-listeners
	warning are omitted: they are Node diagnostics, not event semantics.
	:::
]=]
const function newEventEmitter(): EventEmitter
	const state: EventEmitterState = { _listeners = {} }
	local emitter: EventEmitter

	local function addImpl(
		eventName: string,
		listener: EventEmitterListener,
		once: boolean,
		prepend: boolean
	): EventEmitter
		local list = state._listeners[eventName]
		if list == nil then
			list = {}
			state._listeners[eventName] = list
		end
		const wrapped: Wrapped = { original = listener, once = once }
		if prepend then
			table.insert(list, 1, wrapped)
		else
			table.insert(list, wrapped)
		end
		return emitter
	end

	local function removeImpl(eventName: string, listener: EventEmitterListener): EventEmitter
		local list = state._listeners[eventName]
		if list ~= nil then
			-- Node removes the most recently added matching instance; walking
			-- backward makes the first hit that one.
			for index = #list, 1, -1 do
				if list[index].original == listener then
					table.remove(list, index)
					break
				end
			end
			if #list == 0 then
				state._listeners[eventName] = nil
			end
		end
		return emitter
	end

	emitter = setmetatable(
		{} :: any,
		{
			__index = function(_self: any, key: any): any
				if key == "on" or key == "addListener" then
					return function(_self2: any, eventName: string, listener: EventEmitterListener)
						requireEventName(eventName)
						requireListener(listener)
						return addImpl(eventName, listener, false, false)
					end
				elseif key == "once" then
					return function(_self2: any, eventName: string, listener: EventEmitterListener)
						requireEventName(eventName)
						requireListener(listener)
						return addImpl(eventName, listener, true, false)
					end
				elseif key == "prependListener" then
					return function(_self2: any, eventName: string, listener: EventEmitterListener)
						requireEventName(eventName)
						requireListener(listener)
						return addImpl(eventName, listener, false, true)
					end
				elseif key == "off" or key == "removeListener" then
					return function(_self2: any, eventName: string, listener: EventEmitterListener)
						requireEventName(eventName)
						requireListener(listener)
						return removeImpl(eventName, listener)
					end
				elseif key == "emit" then
					return function(_self2: any, eventName: string, ...: any): boolean
						requireEventName(eventName)
						local list = state._listeners[eventName]
						if list == nil or #list == 0 then
							if eventName == "error" then
								-- Node with no error listener crashes the process;
								-- the portable equivalent: re-throw the reason.
								error((select(1, ...) :: any) or "Unhandled 'error' event", 2)
							end
							return false
						end
						-- Snapshot: like Node, a remove during emit does not stop
						-- listeners already scheduled for this emit.
						const snapshot = table.clone(list)
						local fired = 0
						for _, wrapped in snapshot do
							-- `once` listeners are removed before their call, so a
							-- second emit does not see them.
							if wrapped.once then
								for index = #list, 1, -1 do
									if list[index] == wrapped then
										table.remove(list, index)
										break
									end
								end
							end
							(wrapped.original :: EventEmitterListener)(...)
							fired += 1
						end
						if #list == 0 then
							state._listeners[eventName] = nil
						end
						return fired > 0
					end
				elseif key == "eventNames" then
					return function(_self2: any): { string }
						local names: { string } = {}
						for eventName in state._listeners do
							table.insert(names, eventName)
						end
						return names
					end
				elseif key == "listenerCount" then
					return function(_self2: any, eventName: string): number
						local list = state._listeners[eventName]
						return if list == nil then 0 else #list
					end
				end
				return nil
			end,
		} :: any
	) :: EventEmitter

	return emitter
end

return table.freeze({ new = newEventEmitter })
