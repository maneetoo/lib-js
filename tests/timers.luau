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

	T:finish()
	return T.passed, T.failed
end
