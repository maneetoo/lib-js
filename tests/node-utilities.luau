--!strict
-- Node.js / Web-platform utilities: atob & btoa, AbortController &
-- AbortSignal, EventTarget & Event & EventEmitter.

local T = require("./_init").new("node-utilities")
local loader = require("./_loader")

local base64 = loader.loadPackage("atob-btoa") :: any
local abort = loader.loadPackage("abort") :: any
local events = loader.loadPackage("events") :: any

return function(): (number, number)
	-- atob / btoa: JS reference vectors
	do
		local vectors = {
			{ "hello", "aGVsbG8=" },
			{ "f", "Zg==" },
			{ "fo", "Zm8=" },
			{ "foo", "Zm9v" },
			{ "foob", "Zm9vYg==" },
			{ "fooba", "Zm9vYmE=" },
			{ "foobar", "Zm9vYmFy" },
			{ "", "" },
			{ "\255\254\253", "//79" },
		}
		for _, vector in vectors do
			T:check(`btoa("{vector[1]:sub(1, 8)}")`, base64.btoa(vector[1]) == vector[2])
			T:check(`atob("{vector[2]}")`, base64.atob(vector[2]) == vector[1])
		end

		-- Latin-1 characters are code points <= 0xFF: accepted, raw bytes
		T:check("btoa Latin-1 accented text", base64.btoa("caf\xe9") == "Y2Fm6Q==")

		-- forgiving padding on decode
		T:check("atob without padding", base64.atob("Zm9vYg") == "foob")

		-- strict failures (é and ö are Latin-1 code points and legal; chars
		-- beyond 0xFF are what btoa rejects)
		T:expectError("btoa rejects non-Latin1 characters", function()
			base64.btoa("héllo wörld ✓")
		end)
		T:expectError("btoa rejects an emoji", function()
			base64.btoa("😀")
		end)
		T:expectError("btoa rejects CJK", function()
			base64.btoa("文")
		end)
		T:expectError("atob rejects invalid alphabet characters", function()
			base64.atob("SGVsbG8-")
		end)
		T:expectError("atob rejects whitespace", function()
			base64.atob("SGVs bG8=")
		end)
		T:expectError("atob rejects padding in the middle", function()
			base64.atob("SG=VsbG8=")
		end)
		T:expectError("atob rejects wrong-length padding", function()
			base64.atob("Zg=")
		end)
		T:expectError("atob rejects triple padding", function()
			base64.atob("Zg===")
		end)
		T:expectError("atob rejects undecodable remainder", function()
			base64.atob("Z")
		end)
		T:expectError("btoa rejects non-string input", function()
			base64.btoa(42)
		end)
		T:expectError("atob rejects non-string input", function()
			base64.atob(nil)
		end)
	end

	-- AbortController / AbortSignal
	do
		local controller = abort.AbortController.new()
		T:check("aborted starts false", controller.signal.aborted == false)
		T:check("reason nil before abort", controller.signal.reason == nil)

		local fired: { string } = {}
		controller.signal:addEventListener("abort", function()
			table.insert(fired, "l1")
		end)
		controller:abort()
		T:check("aborted flips true", controller.signal.aborted == true)
		T:check("listener fired once", #fired == 1)
		T:check("default reason name", controller.signal.reason.name == "AbortError")
		T:check("default reason message", controller.signal.reason.message == "signal is aborted without reason")

		-- second abort is a no-op: first reason and one event
		controller:abort("second")
		T:check("second abort ignored", controller.signal.reason.name == "AbortError" and #fired == 1)

		-- late listeners never fire
		controller.signal:addEventListener("abort", function()
			table.insert(fired, "late")
		end)
		T:check("late listener never fires", #fired == 1)

		-- custom reason, also sticky
		local custom = abort.AbortController.new()
		custom:abort({ marker = "mine" })
		custom:abort("later")
		T:check("custom reason stored", custom.signal.reason.marker == "mine")

		-- throwIfAborted
		local ok, thrown = pcall(function()
			controller.signal:throwIfAborted()
		end)
		T:check("throwIfAborted throws the reason", not ok and thrown.name == "AbortError")
		local fresh = abort.AbortController.new()
		T:check(
			"throwIfAborted no-op when live",
			pcall(function()
				fresh.signal:throwIfAborted()
			end)
		)

		-- removeEventListener
		local calls = 0
		local listener = function()
			calls += 1
		end
		fresh.signal:addEventListener("abort", listener)
		fresh.signal:removeEventListener("abort", listener)
		fresh:abort()
		T:check("removed listener not called", calls == 0)

		-- duplicate registration collapses
		local dup = abort.AbortController.new()
		local dups = 0
		local fn = function()
			dups += 1
		end
		dup.signal:addEventListener("abort", fn)
		dup.signal:addEventListener("abort", fn)
		dup:abort()
		T:check("duplicate abort listeners collapse", dups == 1)
	end

	-- AbortSignal statics
	do
		local immediate = abort.AbortSignal.abort()
		T:check("static abort aborted", immediate.aborted == true)
		T:check("static abort default reason", immediate.reason.name == "AbortError")
		local withReason = abort.AbortSignal.abort("mine")
		T:check("static abort custom reason", withReason.reason == "mine")

		-- any: follows the first abort
		local a, b = abort.AbortController.new(), abort.AbortController.new()
		local combined = abort.AbortSignal.any({ a.signal, b.signal })
		T:check("any starts live", combined.aborted == false)
		b:abort("from-b")
		T:check("any follows first abort", combined.aborted == true and combined.reason == "from-b")

		-- any adopts an already-aborted source
		local pre = abort.AbortSignal.abort("pre")
		local adopted = abort.AbortSignal.any({ abort.AbortController.new().signal, pre })
		T:check("any adopts aborted source", adopted.aborted == true and adopted.reason == "pre")

		-- timeout: fires through the Timers scheduler with a virtual clock
		local Timers = loader.loadPackage("Timers") :: any
		local virtualTime = 0
		Timers.setClock(function()
			return virtualTime
		end)
		Timers.setSleep(function(_seconds) end)
		local timed = abort.AbortSignal.timeout(50)
		T:check("timeout pending before due", timed.aborted == false)
		virtualTime = 51
		Timers.step()
		T:check("timeout aborts after ms", timed.aborted == true)
		T:check("timeout reason name", timed.reason.name == "TimeoutError")
		T:check("timeout reason message", timed.reason.message == "signal timed out")

		T:expectError("timeout rejects non-number ms", function()
			abort.AbortSignal.timeout("soon")
		end)
		T:expectError("any rejects non-table", function()
			abort.AbortSignal.any(5)
		end)
	end

	-- EventTarget / Event
	do
		local target = events.EventTarget.new()
		local seen: { string } = {}
		target:addEventListener("ping", function(event)
			table.insert(seen, event.type)
		end)
		local dispatched = target:dispatchEvent(events.Event.new("ping"))
		T:check("dispatch runs the listener", #seen == 1 and seen[1] == "ping")
		T:check("dispatch returns true", dispatched == true)

		-- Web rule: same (type, listener) registers once
		local count = 0
		local fn = function()
			count += 1
		end
		target:addEventListener("ping", fn)
		target:addEventListener("ping", fn)
		target:dispatchEvent(events.Event.new("ping"))
		T:check("duplicate registration collapses", count == 1)

		-- registration order
		local order: { string } = {}
		target:addEventListener("ordered", function()
			table.insert(order, "first")
		end)
		target:addEventListener("ordered", function()
			table.insert(order, "second")
		end)
		target:dispatchEvent(events.Event.new("ordered"))
		T:check("listeners run in order", table.concat(order, ",") == "first,second")

		-- removeEventListener
		target:removeEventListener("ordered", fn)
		local none = target:dispatchEvent(events.Event.new("never"))
		T:check("no listeners returns true", none == true)

		-- cancelable / preventDefault
		local canceller = events.EventTarget.new()
		canceller:addEventListener("cancel-me", function(event)
			event:preventDefault()
		end)
		T:check(
			"preventDefault returns false when cancelable",
			canceller:dispatchEvent(events.Event.new("cancel-me", { cancelable = true })) == false
		)
		T:check(
			"preventDefault inert when not cancelable",
			canceller:dispatchEvent(events.Event.new("cancel-me")) == true
		)
		local inert = events.Event.new("no-cancel")
		inert:preventDefault()
		T:check("preventDefault no-op off-dispatch", inert.defaultPrevented == false)

		-- Event fields
		local event = events.Event.new("typed")
		T:check("event type", event.type == "typed")
		T:check("event not cancelable by default", event.cancelable == false)
		T:check("event not prevented by default", event.defaultPrevented == false)

		T:expectError("Event.new rejects non-string type", function()
			events.Event.new(42)
		end)
		T:expectError("addEventListener rejects non-function", function()
			events.EventTarget.new():addEventListener("x", "not a function")
		end)
	end

	-- EventEmitter
	do
		local emitter = events.EventEmitter.new()
		local received: { any } = {}
		emitter:on("data", function(chunk)
			table.insert(received, chunk)
		end)
		T:check("emit returns true with listeners", emitter:emit("data", "hello") == true)
		T:check("listener received args", received[1] == "hello")
		T:check("emit returns false without listeners", emitter:emit("nope") == false)

		-- duplicates: each registration fires
		local dupCount = 0
		local dupListener = function()
			dupCount += 1
		end
		emitter:on("dup", dupListener)
		emitter:on("dup", dupListener)
		emitter:emit("dup")
		T:check("duplicate registrations each fire", dupCount == 2)

		-- addListener alias
		local alias = events.EventEmitter.new()
		alias:addListener("x", function() end)
		T:check("addListener registers", alias:emit("x") == true)

		-- once: removed then invoked, at most once
		local onceCount = 0
		emitter:once("once", function()
			onceCount += 1
		end)
		emitter:emit("once")
		emitter:emit("once")
		T:check("once fires exactly once", onceCount == 1)

		-- prependListener
		local prependOrder: { string } = {}
		emitter:on("pre", function()
			table.insert(prependOrder, "second")
		end)
		emitter:prependListener("pre", function()
			table.insert(prependOrder, "first")
		end)
		emitter:emit("pre")
		T:check("prependListener runs first", table.concat(prependOrder, ",") == "first,second")

		-- removeListener: peels one instance, returns the emitter
		T:check("removeListener chains", emitter:removeListener("dup", dupListener) == emitter)
		T:check("one duplicate left", emitter:listenerCount("dup") == 1)
		emitter:removeListener("dup", dupListener)
		T:check("all duplicates removed", emitter:listenerCount("dup") == 0)

		-- off alias
		local offEmitter = events.EventEmitter.new()
		local offFn = function() end
		offEmitter:on("o", offFn)
		offEmitter:off("o", offFn)
		T:check("off removes", offEmitter:emit("o") == false)

		-- eventNames / listenerCount
		local names = emitter:eventNames()
		local hasData = false
		for _, name in names do
			if name == "data" then
				hasData = true
			end
		end
		T:check("eventNames lists events", hasData)

		-- unhandled error event re-throws
		T:expectError("emit error without listeners rethrows", function()
			emitter:emit("error", "boom")
		end)
		-- with a listener it is a normal event
		local handled = {}
		emitter:on("error", function(reason)
			table.insert(handled, reason)
		end)
		emitter:emit("error", "handled")
		T:check("error with listener is normal", handled[1] == "handled")

		-- a removal during emit does not stop already-scheduled listeners
		local mid = events.EventEmitter.new()
		local midCalls: { string } = {}
		local tail = function()
			table.insert(midCalls, "tail")
		end
		mid:on("mid", function()
			table.insert(midCalls, "head")
			mid:removeListener("mid", tail)
		end)
		mid:on("mid", tail)
		mid:emit("mid")
		T:check("remove during emit still runs scheduled", table.concat(midCalls, ",") == "head,tail")

		T:expectError("on rejects non-string eventName", function()
			emitter:on(42, function() end)
		end)
		T:expectError("on rejects non-function listener", function()
			emitter:on("x", "nope")
		end)
	end

	T:finish()
	return T.passed, T.failed
end
