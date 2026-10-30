--!strict

--[=[
	@class EventTarget
	@within EventTarget

	Web platform's
	[`EventTarget`](https://developer.mozilla.org/en-US/docs/Web/API/EventTarget)
	constructor table: `EventTarget.new()`.
]=]

const EventModule = require("./Event")
const TypeError = require("../Error")

type Event = EventModule.Event

--[=[
	@within EventTarget
	@type EventListener = (event: Event) -> ()

	A listener registered on a target. It receives the dispatched `Event`.
]=]
export type EventListener = (event: Event) -> ()

--[=[
	@within EventTarget
	@type EventTarget = { addEventListener: ..., removeEventListener: ..., dispatchEvent: ... }

	An event target: registration, removal, and dispatch for typed
	listeners.
]=]
export type EventTarget = {
	addEventListener: (self: EventTarget, type: string, listener: EventListener) -> (),
	removeEventListener: (self: EventTarget, type: string, listener: EventListener) -> (),
	dispatchEvent: (self: EventTarget, event: Event) -> boolean,
}

type EventTargetState = {
	_listeners: { [string]: { EventListener } },
}

--[=[
	@within EventTarget
	@return EventTarget -- a new, empty target

	`EventTarget.new()` (JS: `new EventTarget()`). The target exposes:

	- `addEventListener(type, listener)` — registers a listener for the
	  event `type`; the **Web rule** collapses duplicate `(type, listener)`
	  registrations to one invocation
	- `removeEventListener(type, listener)` — removes one registration; a
	  never-registered pair is a no-op
	- `dispatchEvent(event)` — runs the listeners of `event.type` in
	  registration order from a snapshot (listeners added mid-dispatch do
	  not run for that event); returns `false` only when the event is
	  `cancelable` **and** `preventDefault()` was called, otherwise `true`

	:::caution
	A structural, minimal port: no capture/bubble phases, no DOM tree
	propagation, no `passive` listeners. Listener identity for
	deduplication is the `(type, listener)` pair — the Web rule minus the
	capture flag.
	:::
]=]
const function newEventTarget(): EventTarget
	const state: EventTargetState = { _listeners = {} }
	return setmetatable(
		{} :: any,
		{
			__index = function(_self: any, key: any): any
				if key == "addEventListener" then
					return function(_self2: any, eventType: string, listener: EventListener)
						if type(eventType) ~= "string" then
							error(TypeError.new("EventTarget.addEventListener: type must be a string"), 2)
						end
						if type(listener) ~= "function" then
							error(TypeError.new("EventTarget.addEventListener: listener must be a function"), 2)
						end
						local list = state._listeners[eventType]
						if list == nil then
							list = {}
							state._listeners[eventType] = list
						end
						-- Web rule: the same (type, listener) pair registers once.
						for _, existing in list do
							if existing == listener then
								return
							end
						end
						table.insert(list, listener)
					end
				elseif key == "removeEventListener" then
					return function(_self2: any, eventType: string, listener: EventListener)
						local list = state._listeners[eventType]
						if list == nil then
							return
						end
						for index, existing in list do
							if existing == listener then
								table.remove(list, index)
								return
							end
						end
					end
				elseif key == "dispatchEvent" then
					return function(_self2: any, event: Event): boolean
						if type(event) ~= "table" or type((event :: any).type) ~= "string" then
							error(TypeError.new("EventTarget.dispatchEvent: argument must be an Event"), 2)
						end
						local list = state._listeners[(event :: any).type]
						if list == nil or #list == 0 then
							return true
						end
						-- Snapshot: listeners added during dispatch do not run for
						-- this event; removals during dispatch are honoured.
						const snapshot = table.clone(list)
						for _, listener in snapshot do
							for _, existing in list do
								if existing == listener then
									listener(event)
									break
								end
							end
						end
						if (event :: any).defaultPrevented == true then
							return false
						end
						return true
					end
				end
				return nil
			end,
		} :: any
	) :: EventTarget
end

return table.freeze({ new = newEventTarget })
