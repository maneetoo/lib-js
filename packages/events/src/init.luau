--!strict

--[=[
	@class events

	Two event systems in one package, as JavaScript has them:

	- **`EventTarget` / `Event`** — the Web platform API
	  ([`EventTarget`](https://developer.mozilla.org/en-US/docs/Web/API/EventTarget),
	  [`Event`](https://developer.mozilla.org/en-US/docs/Web/API/Event)):
	  minimal, deduplicating, ordered, `dispatchEvent` with cancelable
	  default-prevention.
	- **`EventEmitter`** — Node.js
	  [`events`](https://nodejs.org/api/events.html): duplicate registrations
	  each fire, `once`, `emit` returning whether listeners ran, chaining
	  add/remove.

	```lua
	local events = require(path.to.events)

	local target = events.EventTarget.new()
	target.addEventListener("ping", function(event)
		print(event.type) -- "ping"
	end)
	target.dispatchEvent(events.Event.new("ping"))

	local emitter = events.EventEmitter.new()
	emitter:on("data", function(chunk)
		print("got", chunk)
	end)
	emitter:emit("data", "hello") -- true
	```

	:::caution
	`EventTarget` here is a structural, minimal port: no capture/bubble
	phases, no DOM tree propagation, no `passive` listeners (there is no
	scrolling to block). Identity for deduplication is the
	`(type, listener)` pair, which is the Web rule minus the capture flag.
	:::

	:::caution
	Node's unhandled-`error`-event process crash cannot be reproduced
	portably; an `emit("error", ...)` with no listeners re-throws the
	error out of `emit` instead (the closest portable behaviour, and what
	Node itself does when the listener exists). Listener errors likewise
	propagate out of `emit` rather than being routed to an `error` event.
	:::

	:::note
	`newListener`/`removeListener` meta-events and the max-listeners
	warning are omitted: they are Node diagnostics, not event semantics.
	:::
]=]

const TypeError = require("./Error").TypeError

type Listener = (event: any) -> ()
type EventEmitterListener = (...any) -> ()

--[=[
	@within events
	@type EventOptions = { cancelable: boolean? }

	Options for `Event.new`.
]=]
export type EventOptions = { cancelable: boolean? }

--[=[
	@within events
	@type Event = { read type: string, read cancelable: boolean, read defaultPrevented: boolean, preventDefault: (self: Event) -> () }

	A Web-platform event: `type`, `cancelable`, `defaultPrevented`, and
	`preventDefault()`.
]=]
export type Event = {
	read type: string,
	read cancelable: boolean,
	read defaultPrevented: boolean,
	preventDefault: (self: Event) -> (),
}

type EventState = Event & { _cancelable: boolean, _defaultPrevented: boolean }

--[=[
	@within events
	@prop Event EventStatic

	The `Event` constructor table.
]=]

--[=[
	@within events
	@param type string -- the event type; case-sensitive
	@param options EventOptions? -- `{ cancelable = true }` makes `preventDefault` effective
	@return Event -- the new event

	Builds an event. `cancelable` defaults to `false`; `preventDefault()` on a
	non-cancelable event does nothing (matching the platform).
]=]
local function newEvent(eventType: string, options: EventOptions?): Event
	if type(eventType) ~= "string" then
		error(TypeError.new("Event: type must be a string"), 2)
	end
	const cancelable = options ~= nil and options.cancelable == true
	const event: EventState = {
		type = eventType,
		_cancelable = cancelable,
		cancelable = cancelable,
		_defaultPrevented = false,
		defaultPrevented = false,
	}
	const mt = {
		__index = function(self: any, key: any): any
			if key == "preventDefault" then
				return function(_self: any)
					if (self :: EventState)._cancelable then
						(self :: EventState)._defaultPrevented = true
						(self :: EventState).defaultPrevented = true
					end
				end
			end
			return rawget(self, key)
		end,
	}
	return setmetatable(event :: any, mt :: any) :: Event
end

const Event = table.freeze({ new = newEvent }) :: any

--[=[
	@within events
	@type EventTarget = { addEventListener: ..., removeEventListener: ..., dispatchEvent: ... }

	A Web-platform event target.
]=]
export type EventTarget = {
	addEventListener: (self: EventTarget, type: string, listener: Listener) -> (),
	removeEventListener: (self: EventTarget, type: string, listener: Listener) -> (),
	dispatchEvent: (self: EventTarget, event: Event) -> boolean,
}

type EventTargetState = {
	_listeners: { [string]: { Listener } },
}

--[=[
	@within events
	@return EventTarget -- a new, empty target

	`EventTarget.new()` (JS: `new EventTarget()`).
]=]
local function newEventTarget(): EventTarget
	const target: EventTargetState = { _listeners = {} }
	return setmetatable(
		target :: any,
		{
			__index = function(self: any, key: any): any
				if key == "addEventListener" then
					return function(_self: any, eventType: string, listener: Listener)
						if type(eventType) ~= "string" then
							error(TypeError.new("EventTarget.addEventListener: type must be a string"), 2)
						end
						if type(listener) ~= "function" then
							error(TypeError.new("EventTarget.addEventListener: listener must be a function"), 2)
						end
						local list = (self :: EventTargetState)._listeners[eventType]
						if list == nil then
							list = {}
							(self :: EventTargetState)._listeners[eventType] = list
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
					return function(_self: any, eventType: string, listener: Listener)
						local list = (self :: EventTargetState)._listeners[eventType]
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
					return function(_self: any, event: Event): boolean
						if type(event) ~= "table" or type((event :: any).type) ~= "string" then
							error(TypeError.new("EventTarget.dispatchEvent: argument must be an Event"), 2)
						end
						local list = (self :: EventTargetState)._listeners[(event :: any).type]
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

const EventTarget = table.freeze({ new = newEventTarget }) :: any

--[=[
	@within events
	@type EventEmitter = { on: ..., addListener: ..., once: ..., off: ..., removeListener: ..., emit: ..., prependListener: ..., eventNames: ..., listenerCount: ... }

	A Node.js EventEmitter.
]=]
export type EventEmitter = {
	on: (self: EventEmitter, eventName: string, listener: EventEmitterListener) -> EventEmitter,
	addListener: (self: EventEmitter, eventName: string, listener: EventEmitterListener) -> EventEmitter,
	once: (self: EventEmitter, eventName: string, listener: EventEmitterListener) -> EventEmitter,
	off: (self: EventEmitter, eventName: string, listener: EventEmitterListener) -> EventEmitter,
	removeListener: (self: EventEmitter, eventName: string, listener: EventEmitterListener) -> EventEmitter,
	prependListener: (self: EventEmitter, eventName: string, listener: EventEmitterListener) -> EventEmitter,
	emit: (self: EventEmitter, eventName: string, ...any) -> boolean,
	eventNames: (self: EventEmitter) -> { string },
	listenerCount: (self: EventEmitter, eventName: string) -> number,
}

type Wrapped = { original: EventEmitterListener, once: boolean, call: EventEmitterListener }

type EventEmitterState = {
	_listeners: { [string]: { Wrapped } },
}

local function requireEventName(eventName: string)
	if type(eventName) ~= "string" then
		error(TypeError.new("EventEmitter: eventName must be a string"), 3)
	end
end

local function requireListener(listener: EventEmitterListener)
	if type(listener) ~= "function" then
		error(TypeError.new("EventEmitter: listener must be a function"), 3)
	end
end

local function wrapListener(listener: EventEmitterListener, once: boolean): Wrapped
	return {
		original = listener,
		once = once,
		-- `once` listeners are removed by `emit` before this is invoked,
		-- exactly as Node documents `once`.
		call = listener,
	}
end

local function addImpl(
	self: EventEmitterState,
	eventName: string,
	listener: EventEmitterListener,
	once: boolean,
	prepend: boolean
): EventEmitter
	local list = self._listeners[eventName]
	if list == nil then
		list = {}
		self._listeners[eventName] = list
	end
	const wrapped = wrapListener(listener, once)
	if prepend then
		table.insert(list, 1, wrapped)
	else
		table.insert(list, wrapped)
	end
	return self :: any
end

local function removeImpl(self: EventEmitterState, eventName: string, listener: EventEmitterListener): EventEmitter
	local list = self._listeners[eventName]
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
			self._listeners[eventName] = nil
		end
	end
	return self :: any
end

--[=[
	@within events
	@return EventEmitter -- a new, empty emitter

	`EventEmitter.new()` (JS: `new EventEmitter()`).
]=]
local function newEventEmitter(): EventEmitter
	const emitter: EventEmitterState = { _listeners = {} }
	return setmetatable(
		emitter :: any,
		{
			__index = function(self: any, key: any): any
				const state = self :: EventEmitterState
				if key == "on" or key == "addListener" then
					return function(_self: any, eventName: string, listener: EventEmitterListener)
						requireEventName(eventName)
						requireListener(listener)
						return addImpl(state, eventName, listener, false, false)
					end
				elseif key == "once" then
					return function(_self: any, eventName: string, listener: EventEmitterListener)
						requireEventName(eventName)
						requireListener(listener)
						return addImpl(state, eventName, listener, true, false)
					end
				elseif key == "prependListener" then
					return function(_self: any, eventName: string, listener: EventEmitterListener)
						requireEventName(eventName)
						requireListener(listener)
						return addImpl(state, eventName, listener, false, true)
					end
				elseif key == "off" or key == "removeListener" then
					return function(_self: any, eventName: string, listener: EventEmitterListener)
						requireEventName(eventName)
						requireListener(listener)
						return removeImpl(state, eventName, listener)
					end
				elseif key == "emit" then
					return function(_self: any, eventName: string, ...: any): boolean
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
							wrapped.call(...)
							fired += 1
						end
						if #list == 0 then
							state._listeners[eventName] = nil
						end
						return fired > 0
					end
				elseif key == "eventNames" then
					return function(_self: any): { string }
						local names: { string } = {}
						for eventName in state._listeners do
							table.insert(names, eventName)
						end
						return names
					end
				elseif key == "listenerCount" then
					return function(_self: any, eventName: string): number
						local list = state._listeners[eventName]
						return if list == nil then 0 else #list
					end
				end
				return nil
			end,
		} :: any
	) :: EventEmitter
end

const EventEmitter = table.freeze({ new = newEventEmitter }) :: any

return table.freeze({
	Event = Event,
	EventTarget = EventTarget,
	EventEmitter = EventEmitter,
})
