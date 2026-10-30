--!strict
-- queueMicrotask, structuredClone, and the uri package (encodeURI* / decodeURI*).

local T = require("./_init").new("globals")
local loader = require("./_loader")

local queueMicrotask = loader.loadPackage("queueMicrotask") :: any
local structuredClone = loader.loadPackage("structuredClone") :: any
local uri = loader.loadPackage("uri") :: any
local Promise = loader.loadPackage("Promise") :: any
local Map = loader.loadPackage("Map") :: any
local Set = loader.loadPackage("Set") :: any
local Error = loader.loadPackage("Error") :: any

return function(): (number, number)
	-- queueMicrotask
	do
		-- runs after current code, FIFO with promise reactions
		local order: { string } = {}
		queueMicrotask(function()
			table.insert(order, "microtask")
		end)
		local p = Promise.resolve(nil)
		p["then"](p, function()
			table.insert(order, "promise")
		end)
		queueMicrotask(function()
			table.insert(order, "microtask2")
		end)
		table.insert(order, "sync")
		T:check("callback not run synchronously", #order == 1 and order[1] == "sync")
		Promise.__runJobs()
		T:check(
			"FIFO interleaving with promise reactions",
			table.concat(order, ",") == "sync,microtask,promise,microtask2"
		)

		-- runs before timers (macrotasks)
		local ran: { string } = {}
		local Timers = loader.loadPackage("Timers") :: any
		local virtualTime = 0
		Timers.setClock(function()
			return virtualTime
		end)
		Timers.setSleep(function(_seconds) end)
		Timers.setTimeout(function()
			table.insert(ran, "timeout")
		end, 1)
		queueMicrotask(function()
			table.insert(ran, "microtask")
		end)
		Promise.__runJobs()
		virtualTime = 2
		Timers.step()
		T:check("microtask before timer", ran[1] == "microtask" and ran[2] == "timeout")

		-- errors thrown inside the callback are not swallowed: they surface
		-- as an unhandled rejection reported to the rejection tracker (the
		-- same reporting path a Promise reaction gets)
		local rejections: { any } = {}
		Promise.__setRejectionTracker(function(_promise, reason)
			table.insert(rejections, reason)
		end)
		queueMicrotask(function()
			error({ marker = "thrown in microtask" })
		end)
		Promise.__runJobs()
		Promise.__runJobs()
		T:check("microtask error reported, not swallowed", #rejections == 1)
		T:check(
			"reported reason is the thrown value",
			type(rejections[1]) == "table" and rejections[1].marker == "thrown in microtask"
		)
		Promise.__setRejectionTracker(nil)

		-- non-function throws TypeError immediately
		T:expectError("non-callable queueMicrotask", function()
			queueMicrotask("not a function")
		end)

		-- returns nothing
		T:check("returns nil", queueMicrotask(function() end) == nil)
	end

	-- structuredClone
	do
		-- deep clone: nested tables are copied, not shared
		local original = { list = { 1, 2, 3 }, inner = { deep = { value = "v" } } }
		local clone = structuredClone(original)
		clone.list[1] = 99
		clone.inner.deep.value = "mutated"
		T:check("deep clone isolates arrays", original.list[1] == 1)
		T:check("deep clone isolates nested tables", original.inner.deep.value == "v")
		T:check("clone carries values", clone.list[2] == 2 and clone.inner.deep.value == "mutated")

		-- primitives pass through by value
		T:check("clone number", structuredClone(42) == 42)
		T:check("clone string", structuredClone("x") == "x")
		T:check("clone boolean", structuredClone(true) == true)
		T:check("clone nil", structuredClone(nil) == nil)

		-- shared references stay shared in the clone
		local shared = { x = 1 }
		local container = { a = shared, b = shared }
		local containerClone = structuredClone(container)
		T:check("shared reference stays shared", containerClone.a == containerClone.b)
		T:check("shared clone is a new table", containerClone.a ~= shared)

		-- circular references are preserved
		local cyclic = { name = "c" }
		cyclic.itself = cyclic
		local cyclicClone = structuredClone(cyclic)
		T:check("cycle preserved", cyclicClone.itself == cyclicClone)
		T:check("cycle is a distinct clone", cyclicClone.itself ~= cyclic)
		T:check("cycle field value", cyclicClone.name == "c")

		-- this library's Map
		local map = Map.new({ { "k", { 1, 2 } }, { nil, "nil-key" } })
		local mapClone = structuredClone(map)
		T:check("Map clone is a Map", mapClone.size == 2)
		T:check("Map clone values cloned", mapClone.get(mapClone, "k")[1] == 1)
		T:check("Map clone value is new", mapClone.get(mapClone, "k") ~= map.get(map, "k"))
		T:check("Map nil key survives", mapClone.get(mapClone, nil) == "nil-key")

		-- this library's Set
		local set = Set.new({ 1, 2 })
		local setClone = structuredClone(set)
		T:check("Set clone is a Set", setClone.size == 2)
		T:check("Set clone membership", setClone.has(setClone, 1))

		-- Error, subclasses, cause, AggregateError errors
		local err = Error.new("boom")
		local errClone = structuredClone(err)
		T:check("Error clone message", errClone.message == "boom")
		T:check("Error clone name", errClone.name == "Error")

		local typeError = (Error :: any).TypeError.new("msg", { cause = Error.new("root") })
		local teClone = structuredClone(typeError)
		T:check("TypeError clone keeps class", teClone.name == "TypeError")
		T:check("TypeError clone message", teClone.message == "msg")
		T:check("cause cloned as value", teClone.cause ~= nil and teClone.cause.message == "root")
		T:check("cause clone is a new error", teClone.cause ~= typeError.cause)

		local aggregate = (Error :: any).AggregateError.new({ Error.new("a"), Error.new("b") }, "many")
		local aggClone = structuredClone(aggregate)
		T:check("AggregateError clone name", aggClone.name == "AggregateError")
		T:check("AggregateError errors cloned", #aggClone.errors == 2 and aggClone.errors[1].message == "a")
		T:check("AggregateError errors are new", aggClone.errors[1] ~= aggregate.errors[1])

		-- buffers are byte-copied
		local buf = buffer.create(4)
		buffer.writeu8(buf, 0, 255)
		buffer.writeu32(buf, 0, 0xDEADBEEF)
		local bufClone = structuredClone(buf)
		T:check("buffer clone is a new buffer", bufClone ~= buf)
		T:check("buffer clone contents", buffer.readu32(bufClone, 0) == 0xDEADBEEF)
		buffer.writeu32(bufClone, 0, 0)
		T:check("buffer clone isolated", buffer.readu32(buf, 0) == 0xDEADBEEF)

		-- uncloneable values throw
		T:expectError("function cannot be cloned", function()
			structuredClone(function() end)
		end)
		T:expectError("function nested in table cannot be cloned", function()
			structuredClone({ fn = function() end })
		end)
		T:expectError("thread cannot be cloned", function()
			structuredClone(coroutine.create(function() end))
		end)

		-- unknown tables come back as plain tables (metatable dropped)
		local classy = setmetatable({ x = 1 }, { __index = { y = 2 } })
		local classyClone = structuredClone(classy)
		T:check("unknown table cloned as plain table", classyClone.x == 1)
		T:check("metatable not preserved", getmetatable(classyClone) == nil and classyClone.y == nil)
	end

	-- uri: encodeURI / encodeURIComponent
	do
		T:check(
			"encodeURI keeps structure",
			uri.encodeURI("https://mozilla.org/?q=hello world") == "https://mozilla.org/?q=hello%20world"
		)
		T:check("encodeURI keeps reserved set", uri.encodeURI(";/?:@&=+$,#") == ";/?:@&=+$,#")
		T:check("encodeURI keeps unreserved set", uri.encodeURI("abc123-_.!~*'()") == "abc123-_.!~*'()")
		T:check("encodeURI encodes non-ASCII", uri.encodeURI("https://x/a b?q=é") == "https://x/a%20b?q=%C3%A9")
		T:check(
			"encodeURI round-trips through decodeURI",
			uri.decodeURI(uri.encodeURI("https://x/a b?q=é")) == "https://x/a b?q=é"
		)
		T:check("encodeURI leaves # alone", uri.encodeURI("a#b") == "a#b")

		T:check("encodeURIComponent escapes reserved", uri.encodeURIComponent("Jack & Jill") == "Jack%20%26%20Jill")
		T:check("encodeURIComponent keeps unreserved", uri.encodeURIComponent("abc123-_.!~*'()") == "abc123-_.!~*'()")
		T:check(
			"encodeURIComponent escapes structure",
			uri.encodeURIComponent(";/?:@&=+$,#") == "%3B%2F%3F%3A%40%26%3D%2B%24%2C%23"
		)
		T:check("encodeURIComponent encodes space as %20", uri.encodeURIComponent("a b") == "a%20b")
		T:check(
			"non-ASCII round trip",
			uri.decodeURIComponent(uri.encodeURIComponent("хелло 😀 world")) == "хелло 😀 world"
		)
	end

	-- uri: decodeURI / decodeURIComponent
	do
		T:check("decodeURIComponent decodes reserved", uri.decodeURIComponent("a%2Fb") == "a/b")
		T:check("decodeURIComponent decodes &", uri.decodeURIComponent("Jack%20%26%20Jill") == "Jack & Jill")
		T:check("decodeURI keeps %2F", uri.decodeURI("a%2Fb") == "a%2Fb")
		T:check("decodeURI decodes %20", uri.decodeURI("%2Fa%20b") == "%2Fa b")
		T:check("decodeURI keeps encoded colon", uri.decodeURI("https%3A//x") == "https%3A//x")
		T:check("decodeURI decodes non-ASCII", uri.decodeURI("%C3%A9") == "é")
		T:check("consecutive sequences each decode", uri.decodeURIComponent("%41%42%43") == "ABC")

		-- lowercase hex accepted
		T:check("lowercase hex", uri.decodeURIComponent("%c3%a9") == "é")

		-- malformed input throws URIError
		T:expectError("incomplete percent", function()
			uri.decodeURI("a%2")
		end)
		T:expectError("trailing percent", function()
			uri.decodeURI("abc%")
		end)
		T:expectError("invalid hex digits", function()
			uri.decodeURIComponent("%zz")
		end)
		T:expectError("incomplete UTF-8 sequence", function()
			uri.decodeURIComponent("%C3")
		end)
		T:expectError("bare continuation byte", function()
			uri.decodeURIComponent("%80")
		end)
		T:expectError("overlong form", function()
			uri.decodeURIComponent("%C0%80")
		end)
		T:expectError("surrogate encoded", function()
			uri.decodeURIComponent("%ED%A0%80")
		end)
		T:expectError("beyond U+10FFFF", function()
			uri.decodeURIComponent("%F5%80%80%80")
		end)

		-- non-string arguments throw TypeError
		T:expectError("encodeURI non-string", function()
			uri.encodeURI(42)
		end)
		T:expectError("decodeURIComponent non-string", function()
			uri.decodeURIComponent(nil)
		end)
	end

	T:finish()
	return T.passed, T.failed
end
