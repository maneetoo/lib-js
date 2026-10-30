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
	target:addEventListener("ping", function(event)
		print(event.type) -- "ping"
	end)
	target:dispatchEvent(events.Event.new("ping"))

	local emitter = events.EventEmitter.new()
	emitter:on("data", function(chunk)
		print("got", chunk)
	end)
	emitter:emit("data", "hello") -- true
	```
]=]

return table.freeze({
	Event = require("@self/Event"),
	EventTarget = require("@self/EventTarget"),
	EventEmitter = require("@self/EventEmitter"),
})
