--!strict

--[=[
	@class __scheduler
	@private

	The shared state behind the timer functions. Each timer and each immediate
	is a coroutine. The coroutine yields until the scheduler resumes it, and the
	scheduler resumes it once its due time has come. Luau has no event loop, so
	the host drives it with `step` (one turn) or `run` (until nothing is left).

	Time comes from a clock in milliseconds, and `run` waits with a sleep
	function in seconds. Both can be replaced, because the standard library has
	no wall clock with millisecond resolution and no sleep.
]=]

const Number = require("../Number")

export type Entry = {
	id: number,
	due: number,
	delay: number,
	repeating: boolean,
	co: thread,
}

export type Args = { n: number, [number]: any }
export type Clock = () -> number
export type Sleep = (seconds: number) -> ()

const timers: { [number]: Entry }, immediateThreads: { [number]: thread } = {}, {}
local immediateQueue: { number }, nextId: number = {}, 1

--[=[
	@within __scheduler
	@private
	The default clock. `os.clock` measures CPU time, so it does not advance
	while the host is idle. A host that waits between turns must replace it.
]=]
const function defaultClock(): number
	return os.clock() * 1000
end

local clock: Clock, sleep: Sleep? = defaultClock, nil

--[=[
	@within __scheduler
	@private
	@param fn Clock? -- a function returning milliseconds, or `nil` for the default
]=]
const function setClock(fn: Clock?)
	clock = fn or defaultClock
end

--[=[
	@within __scheduler
	@private
	@param fn Sleep? -- a function that waits for the given seconds, or `nil` to spin
]=]
const function setSleep(fn: Sleep?)
	sleep = fn
end

--[=[
	@within __scheduler
	@private
	@param delay number -- requested delay in milliseconds
	@return number -- the delay the timer uses, an integer from 1 to 2147483647
]=]
const function normalizeDelay(delay: number): number
	if delay ~= delay or delay < 1 or delay > 2147483647 then
		return 1
	end
	return math.floor(delay)
end

--[=[
	@within __scheduler
	@private
	Schedules `callback` as a timer, or as an interval when `repeating` is true.
	The coroutine yields once at the start. That yield is the wait, so the first
	resume that comes after the due time runs the callback.

	An interval is fixed-rate. Its next call is due one `delay` after the
	previous due time, not after the callback ends. If the callback ran past the
	next slot, the count starts again from the current time, so missed calls are
	not made up one after another.
]=]
const function schedule(callback: (...any) -> (), delay: number, args: Args, repeating: boolean): number
	const id: number = nextId
	nextId += 1
	const entry: Entry = {
		id = id,
		due = clock() + delay,
		delay = delay,
		repeating = repeating,
		co = nil :: any,
	}
	entry.co = coroutine.create(function()
		while true do
			coroutine.yield()
			callback(table.unpack(args, 1, args.n))
			-- `clearInterval` inside the callback removes the entry, so it stops here.
			if not repeating or timers[id] ~= entry then
				return
			end
			local nextDue: number = entry.due + delay
			const time: number = clock()
			if nextDue <= time then
				nextDue = time + delay
			end
			entry.due = nextDue
		end
	end)
	timers[id] = entry
	coroutine.resume(entry.co)
	return id
end

--[=[
	@within __scheduler
	@private
	Removes a timer or interval. An unknown id does nothing.
]=]
const function cancel(id: number)
	timers[id] = nil
end

--[=[
	@within __scheduler
	@private
	Queues `callback` to run in the next immediate phase. Returns its id.
]=]
const function immediate(callback: (...any) -> (), args: Args): number
	const id: number = nextId
	nextId += 1
	immediateThreads[id] = coroutine.create(function()
		callback(table.unpack(args, 1, args.n))
	end)
	table.insert(immediateQueue, id)
	return id
end

--[=[
	@within __scheduler
	@private
	Cancels an immediate that has not run yet. An unknown id does nothing.
]=]
const function cancelImmediate(id: number)
	immediateThreads[id] = nil
end

--[=[
	@within __scheduler
	@private
	@return boolean -- `true` if any timer or immediate is still pending
]=]
const function pending(): boolean
	return next(immediateThreads) ~= nil or next(timers) ~= nil
end

--[=[
	@within __scheduler
	@private
	Runs one turn. First the immediates queued before the turn, then each timer
	whose due time has come, earliest first (ties by id, which is creation order).
	An error in a callback is raised again. The work that has not run yet stays
	queued for the next turn.
	@return boolean -- `true` if work is still pending
]=]
const function step(): boolean
	const queue: { number } = immediateQueue
	immediateQueue = {}
	for index, id in queue do
		const co = immediateThreads[id]
		if co ~= nil then
			immediateThreads[id] = nil
			const ok: boolean, err: string? = coroutine.resume(co)
			if not ok then
				-- Keep the ones that have not run yet, ahead of newer immediates.
				local rest: { number } = table.move(queue, index + 1, #queue, 1, {})
				table.move(immediateQueue, 1, #immediateQueue, #rest + 1, rest)
				immediateQueue = rest
				error(err, 0)
			end
		end
	end

	const time: number, due: { Entry } = clock(), {}
	for _, entry in timers do
		if entry.due <= time then
			table.insert(due, entry)
		end
	end
	table.sort(due, function(a: Entry, b: Entry): boolean
		if a.due ~= b.due then
			return a.due < b.due
		end
		return a.id < b.id
	end)
	for _, entry in due do
		-- An earlier callback in this turn may have cleared this timer.
		if timers[entry.id] == entry then
			const ok: boolean, err: string? = coroutine.resume(entry.co)
			if not ok or coroutine.status(entry.co) == "dead" then
				if timers[entry.id] == entry then
					timers[entry.id] = nil
				end
			end
			if not ok then
				error(err, 0)
			end
		end
	end
	return pending()
end

--[=[
	@within __scheduler
	@private
	Runs turns until nothing is pending. When no immediate is queued, it waits
	for the next timer: with the `sleep` function if one was set, otherwise by
	spinning on the clock.
]=]
const function run()
	while pending() do
		if next(immediateThreads) == nil then
			local earliest: number = Number.POSITIVE_INFINITY
			for _, entry in timers do
				if entry.due < earliest then
					earliest = entry.due
				end
			end
			const wait: number = earliest - clock()
			if wait > 0 then
				if sleep then
					sleep(wait / 1000)
				else
					while clock() < earliest do
					end
				end
			end
		end
		step()
	end
end

return table.freeze({
	schedule = schedule,
	cancel = cancel,
	immediate = immediate,
	cancelImmediate = cancelImmediate,
	normalizeDelay = normalizeDelay,
	pending = pending,
	step = step,
	run = run,
	setClock = setClock,
	setSleep = setSleep,
})
