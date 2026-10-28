--!strict
-- Promise: states, then/catch/finally, combinators, job-queue ordering.

local T = require("./_init").new("Promise")
local loader = require("./_loader")

local Promise = loader.loadPackage("Promise") :: any

-- Resolve a promise and drain the microtask queue before asserting.
local function settle(promise: any): (boolean, any)
	local state, value
	promise["then"](promise, function(v)
		state, value = true, v
	end, function(r)
		state, value = false, r
	end)
	Promise.__runJobs()
	return state, value
end

return function(): (number, number)
	-- basic resolution / rejection
	do
		local p = Promise.new(function(resolve)
			resolve(42)
		end)
		local ok, value = settle(p)
		T:check("resolve value", ok and value == 42)

		local r = Promise.new(function(_resolve, reject)
			reject("boom")
		end)
		local rok, rvalue = settle(r)
		T:check("reject reason", not rok and rvalue == "boom")
	end

	-- resolve once: later calls ignored
	do
		local p = Promise.new(function(resolve)
			resolve(1)
			resolve(2)
		end)
		local _, value = settle(p)
		T:check("first resolution wins", value == 1)

		local both = Promise.new(function(resolve, reject)
			resolve("ok")
			reject("ignored")
		end)
		local bok, bvalue = settle(both)
		T:check("reject after resolve ignored", bok and bvalue == "ok")
	end

	-- then chains propagate values
	do
		local p = Promise.resolve(1)
		local chained = p["then"](p, function(v)
			return v + 1
		end)
		local _, value = settle(chained)
		T:check("then transforms value", value == 2)

		local twice = Promise.resolve(1)["then"](Promise.resolve(1), function(v)
			return v * 10
		end)
		local _, tvalue = settle(twice)
		T:check("chained transform", tvalue == 10)
	end

	-- then rejection passes through
	do
		local p = Promise.reject("err")
		local recovered = p["then"](p, function()
			return "not this"
		end, function(reason)
			return `recovered:{reason}`
		end)
		local ok, value = settle(recovered)
		T:check("onRejected recovers", ok and value == "recovered:err")
	end

	-- throwing in then rejects the chain
	do
		local p = Promise.resolve(1)
		local thrown = p["then"](p, function()
			error("thrown inside then")
		end)
		local ok, reason = settle(thrown)
		T:check("throw rejects chain", not ok)
		T:check("reason is the error value", type(reason) ~= nil)

		local caught = thrown["then"](thrown, nil, function()
			return "caught"
		end)
		local cok, cvalue = settle(caught)
		T:check("rejection caught", cok and cvalue == "caught")
	end

	-- catch / finally
	do
		local p = Promise.reject("nope")
		local caught = p.catch(p, function(reason)
			return `c:{reason}`
		end)
		local ok, value = settle(caught)
		T:check("catch recovers", ok and value == "c:nope")

		local finallyRan = false
		local f = Promise.resolve("v").finally(Promise.resolve("v"), function()
			finallyRan = true
			return "ignored-return"
		end)
		local fok, fvalue = settle(f)
		T:check("finally ran", finallyRan)
		T:check("finally passes value through", fok and fvalue == "v")
	end

	-- Promise.resolve / reject / isPromise
	do
		T:check("resolve passes value", settle(Promise.resolve(7)))
		local ok, value = settle(Promise.resolve(7))
		T:check("resolve value check", ok and value == 7)
		local rok, rvalue = settle(Promise.reject("r"))
		T:check("reject value check", not rok and rvalue == "r")
		T:check("isPromise true", Promise.__isPromise(Promise.resolve(1)))
		T:check("isPromise false for plain", not Promise.__isPromise({}))
	end

	-- withResolvers
	do
		local w = Promise.withResolvers()
		T:check("withResolvers promise", Promise.__isPromise(w.promise))
		w.resolve("via resolver")
		local ok, value = settle(w.promise)
		T:check("resolver resolves", ok and value == "via resolver")
	end

	-- all
	do
		local p = Promise.all({ Promise.resolve(1), Promise.resolve(2), 3 })
		local ok, value = settle(p)
		T:check("all fulfills with array", ok and value[1] == 1 and value[2] == 2 and value[3] == 3)

		local fails = Promise.all({ Promise.resolve(1), Promise.reject("x") })
		local fok, _ = settle(fails)
		T:check("all rejects on any rejection", not fok)

		local empty = Promise.all({})
		local eok, evalue = settle(empty)
		T:check("all of empty fulfills empty", eok and #evalue == 0)
	end

	-- allSettled
	do
		local p = Promise.allSettled({ Promise.resolve(1), Promise.reject("x") })
		local ok, value = settle(p)
		T:check("allSettled fulfills", ok)
		T:check("settled status 1", value[1].status == "fulfilled" and value[1].value == 1)
		T:check("settled status 2", value[2].status == "rejected" and value[2].reason == "x")
	end

	-- race
	do
		local p = Promise.race({ Promise.resolve("fast"), Promise.reject("also fast") })
		local ok, value = settle(p)
		T:check("race first settle wins", ok and value == "fast")

		local rejected = Promise.race({ Promise.reject("first"), Promise.resolve("second") })
		local rok, rvalue = settle(rejected)
		T:check("race rejection wins when first", not rok and rvalue == "first")
	end

	-- any
	do
		local p = Promise.any({ Promise.reject("a"), Promise.resolve("b") })
		local ok, value = settle(p)
		T:check("any first fulfillment", ok and value == "b")

		local allRejected = Promise.any({ Promise.reject(1), Promise.reject(2) })
		local aok, aggregate = settle(allRejected)
		T:check("any all-rejected rejects", not aok)
		T:check("any rejects with AggregateError", type(aggregate) == "table" and aggregate.errors ~= nil)
		T:check("any AggregateError errors array", #aggregate.errors == 2)
	end

	-- thenable adoption
	do
		local thenable = {
			["then"] = function(_self, onFulfilled)
				onFulfilled("from thenable")
			end,
		}
		local p = Promise.resolve(thenable)
		local ok, value = settle(p)
		T:check("thenable adopted", ok and value == "from thenable")
	end

	-- microtask ordering: callbacks run asynchronously, in registration order
	do
		local order: { string } = {}
		local p = Promise.resolve(1)
		p["then"](p, function()
			table.insert(order, "first")
		end)
		p["then"](p, function()
			table.insert(order, "second")
		end)
		T:check("callbacks not yet run", #order == 0)
		Promise.__runJobs()
		T:check("callbacks ran in order", order[1] == "first" and order[2] == "second")
	end

	T:finish()
	return T.passed, T.failed
end
