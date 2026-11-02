--!strict
-- Timers: setTimeout/Interval/Immediate, clearing, ordering.

local T = require("./_init").new("Timers")
local loader = require("./_loader")

local Timers = loader.loadPackage("Timers") :: any

-- Deterministic clock: tests advance time by hand instead of sleeping.
local virtualTime = 0
Timers.setClock(function()
	return virtualTime
end)
Timers.setSleep(function(_seconds)
	virtualTime += _seconds * 1000
end)

local function advance(ms: number)
	virtualTime += ms
	Timers.step()
end

return function(): (number, number)
	-- setTimeout fires after the delay, with args
	do
		local fired, gotArg = false, nil
		Timers.setTimeout(function(arg)
			fired, gotArg = true, arg
		end, 50, "payload")
		T:check("not fired before delay", not fired)
		advance(49)
		T:check("still not fired just before", not fired)
		advance(2)
		T:check("fired after delay", fired)
		T:check("args passed", gotArg == "payload")
	end

	-- setTimeout non-function callback errors
	do
		T:expectError("non-callable setTimeout", function()
			Timers.setTimeout("nope", 10)
		end)
	end

	-- clearTimeout prevents firing
	do
		local fired = false
		local id = Timers.setTimeout(function()
			fired = true
		end, 50)
		Timers.clearTimeout(id)
		advance(100)
		T:check("cleared timeout never fires", not fired)
		T:check("clear twice is safe", Timers.clearTimeout(id) == nil or true)
	end

	-- timers fire in id order at the same due time
	do
		local order: { string } = {}
		Timers.setTimeout(function()
			table.insert(order, "a")
		end, 30)
		Timers.setTimeout(function()
			table.insert(order, "b")
		end, 30)
		advance(31)
		T:check("same-due timers in id order", order[1] == "a" and order[2] == "b")
	end

	-- setInterval repeats until cleared
	do
		local ticks = 0
		local id = Timers.setInterval(function()
			ticks += 1
		end, 40)
		advance(41)
		T:check("first tick", ticks == 1)
		advance(40)
		T:check("second tick", ticks == 2)
		Timers.clearInterval(id)
		advance(200)
		T:check("cleared interval stops", ticks == 2)
	end

	-- setTimeout with small/NaN delay clamps to 1ms
	do
		local fired = false
		Timers.setTimeout(function()
			fired = true
		end, 0 / 0)
		advance(1)
		T:check("NaN delay clamps and fires", fired)
	end

	-- setImmediate runs on the next step, before timers
	do
		local order: { string } = {}
		Timers.setImmediate(function()
			table.insert(order, "immediate")
		end)
		Timers.setTimeout(function()
			table.insert(order, "timeout")
		end, 1)
		advance(1)
		T:check("immediate before timeout", order[1] == "immediate" and order[2] == "timeout")
	end

	-- clearImmediate
	do
		local ran = false
		local id = Timers.setImmediate(function()
			ran = true
		end)
		Timers.clearImmediate(id)
		Timers.step()
		T:check("cleared immediate never runs", not ran)
	end

	-- nextTick runs on the next step, with args, and returns nothing
	do
		local fired, gotA, gotB = false, nil, nil
		local result = Timers.nextTick(function(a, b)
			fired, gotA, gotB = true, a, b
		end, "x", "y")
		T:check("nextTick returns nothing", result == nil)
		T:check("nextTick not run synchronously", not fired)
		Timers.step()
		T:check("nextTick runs on step", fired)
		T:check("nextTick args passed", gotA == "x" and gotB == "y")
	end

	-- nextTick non-function callback errors
	do
		T:expectError("non-callable nextTick", function()
			Timers.nextTick("nope")
		end)
	end

	-- nextTick runs before immediates and timers, in FIFO order
	do
		local order: { string } = {}
		Timers.setTimeout(function()
			table.insert(order, "timeout")
		end, 1)
		Timers.setImmediate(function()
			table.insert(order, "immediate")
		end)
		Timers.nextTick(function()
			table.insert(order, "tick1")
		end)
		Timers.nextTick(function()
			table.insert(order, "tick2")
		end)
		advance(1)
		T:check("ticks before immediate before timeout", table.concat(order, ",") == "tick1,tick2,immediate,timeout")
	end

	-- a tick queued by a tick runs in the same drain, after the ticks already queued
	do
		local order: { string } = {}
		Timers.nextTick(function()
			table.insert(order, "a")
			Timers.nextTick(function()
				table.insert(order, "a-nested")
			end)
		end)
		Timers.nextTick(function()
			table.insert(order, "b")
		end)
		Timers.step()
		T:check("nested tick runs in the same step", table.concat(order, ",") == "a,b,a-nested")
	end

	-- ticks run again after each immediate and each timer
	do
		local order: { string } = {}
		Timers.setImmediate(function()
			table.insert(order, "imm1")
			Timers.nextTick(function()
				table.insert(order, "tick-imm1")
			end)
		end)
		Timers.setImmediate(function()
			table.insert(order, "imm2")
		end)
		Timers.setTimeout(function()
			table.insert(order, "t1")
			Timers.nextTick(function()
				table.insert(order, "tick-t1")
			end)
		end, 1)
		Timers.setTimeout(function()
			table.insert(order, "t2")
		end, 1)
		advance(1)
		T:check("ticks drain after each callback", table.concat(order, ",") == "imm1,tick-imm1,imm2,t1,tick-t1,t2")
	end

	-- an error in a tick is raised again, and the ticks behind it stay queued
	do
		local ran = false
		Timers.nextTick(function()
			error("boom", 0)
		end)
		Timers.nextTick(function()
			ran = true
		end)
		T:expectError("tick error is raised again", function()
			Timers.step()
		end)
		T:check("later tick waits after an error", not ran)
		Timers.step()
		T:check("later tick runs on the next step", ran)
	end

	-- run drains a pending tick without waiting for a timer's sleep
	do
		local ran, slept = false, false
		Timers.setSleep(function(seconds)
			slept = true
			virtualTime += seconds * 1000
		end)
		Timers.nextTick(function()
			ran = true
		end)
		Timers.run()
		T:check("run drains a tick", ran)
		T:check("run does not sleep for a tick", not slept)
		Timers.setSleep(function(seconds)
			virtualTime += seconds * 1000
		end)
	end

	T:finish()
	return T.passed, T.failed
end
