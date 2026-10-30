--!strict

--[=[
	@class Event
	@within EventTarget

	Web platform's
	[`Event`](https://developer.mozilla.org/en-US/docs/Web/API/Event)
	constructor table: `Event.new(type, options?)`.
]=]

const TypeError = require("../Error")

--[=[
	@within Event
	@type EventOptions = { cancelable: boolean? }

	Options for `Event.new`.
]=]
export type EventOptions = { cancelable: boolean? }

--[=[
	@within Event
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

--[=[
	@within Event
	@param type string -- the event type; case-sensitive
	@param options EventOptions? -- `{ cancelable = true }` makes `preventDefault` effective
	@return Event -- the new event

	Builds an event. `cancelable` defaults to `false`; `preventDefault()` on a
	non-cancelable event does nothing (matching the platform), and
	`defaultPrevented` starts `false`.
]=]
const function newEvent(eventType: string, options: EventOptions?): Event
	if type(eventType) ~= "string" then
		error(TypeError.new("Event: type must be a string"), 2)
	end
	const cancelable = options ~= nil and options.cancelable == true
	return setmetatable(
		{
			type = eventType,
			cancelable = cancelable,
			defaultPrevented = false,
		} :: any,
		{
			__index = function(self: any, key: any): any
				if key == "preventDefault" then
					return function(_self2: any)
						if self.cancelable and self.defaultPrevented ~= true then
							self.defaultPrevented = true
						end
					end
				end
				return rawget(self, key)
			end,
		} :: any
	) :: Event
end

return table.freeze({ new = newEvent })
