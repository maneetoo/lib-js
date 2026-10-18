--!strict

--[=[
	@class Promise

	A Luau implementation of JavaScript's
	[`Promise`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise).

	A promise represents a value that may not exist yet. It starts *pending*,
	then becomes *fulfilled* with a value or *rejected* with a reason, and never
	changes state again. Callbacks registered with `then`, `catch`, and `finally`
	never run synchronously. They run as microtasks, in the order they were
	queued, once the job queue is drained.

	```lua
	local Promise = require(path.to.Promise)

	local p = Promise.new(function(resolve)
		resolve(42)
	end)

	p.then_(p, function(value)
		print("got", value) -- runs later, not here
	end, nil)

	print("this prints first")
	Promise.__runJobs() -- or let the host scheduler drain the queue
	```

	:::note
	The behaviour follows the ECMAScript `Promise` specification as closely as
	Luau allows. Statics, `then`, `catch`, `finally`, resolution and adoption of
	thenables, unhandled-rejection tracking, and the job-queue ordering follow the
	spec. Differences are listed in the cautions below.
	:::

	:::note
	Microtasks are queued and run by the host. On Roblox, call
	`Promise.__setScheduler(task.defer)` so jobs run automatically. Elsewhere,
	call `Promise.__runJobs()` after the synchronous code that created the
	promises. Jobs queued during a drain run in the same drain, in order.
	:::

	:::note
	Every promise is a base `Promise`. `then`, `catch`, `finally`, and the statics
	always return a new base promise, whatever the receiver is.
	:::

	:::caution
	Luau has no `new` operator, so construction is `Promise.new(executor)`.
	`Promise(executor)` is not provided, because JavaScript forbids calling
	`Promise` without `new` as well.
	:::

	:::caution
	`then` is a reserved word in Luau. Call it as `p["then"](p, onFulfilled, onRejected)`
	or as `p.then_(p, onFulfilled, onRejected)`. Both names refer to the same function.
	:::

	:::caution
	Subclassing is not supported. Luau statics receive no `this`, so every
	promise is a base `Promise`, `then` does not consult `Symbol.species`,
	and `Promise[Symbol.species]` simply returns `Promise`.
	:::

	:::caution
	Combinators take Luau arrays (`{ ... }`) instead of iterables. When the
	argument is not a table, the combinator returns a promise rejected with a
	`TypeError`. It does not throw.
	:::

	:::caution
	Type inference can fail for mixed arrays of plain values and promises, because
	`Awaitable<T>` is `T | Thenable<T>`. Pass the type argument explicitly when the
	analyzer cannot infer it, for example `Promise.all<number>({ p, 2 })`.
	:::

	:::note
	Unhandled rejections are reported to `Promise.__setRejectionTracker(fn)` as
	`fn(promise, reason)`. By default nothing is reported. The check runs when the
	queue empties, not at the moment of rejection, so a rejection that gets a
	handler before then is never reported.
	:::

	:::note
	Per-promise state lives in a weak-keyed side table, so a promise has no
	visible fields: `Object.keys(p)` is empty, and `p.x` falls through to
	`Promise.prototype`.
	:::

	:::note
	Errors raised by this module (`TypeError`, `AggregateError`) are real error
	objects from this library's `Error` hierarchy. Rejection reasons supplied by
	user code are passed through unchanged.
	:::
]=]

const esTypes = require "./ES17-Types"
const Symbol = require "./Symbol"
const Error = require "./Error"
const TypeError, AggregateError = Error.TypeError, Error.AggregateError

--[=[
	@within Promise
	@type Promise<T> = { ["then"]: ..., then_: ..., catch: ..., finally: ... }

	The promise type. `T` is the type of the fulfilment value.

	Methods take the receiver as their first argument, so call them as
	`p.catch(p, onRejected)` or `p.finally(p, onFinally)`.

	:::note
	`then` and `then_` have the same signature and the same behaviour. Use
	`then_` when you do not want to write `["then"]`.
	:::
]=]

export type Promise<T> = {
	read ["then"]: <U, V>(
		self: Promise<T>,
		onFulfilled: ((value: T) -> esTypes.Awaitable<U>)?,
		onRejected: ((reason: unknown) -> esTypes.Awaitable<V>)?
	) -> Promise<U | V>,
	read then_: <U, V>(
		self: Promise<T>,
		onFulfilled: ((value: T) -> esTypes.Awaitable<U>)?,
		onRejected: ((reason: unknown) -> esTypes.Awaitable<V>)?
	) -> Promise<U | V>,
	read catch: <U>(self: Promise<T>, onRejected: ((reason: unknown) -> esTypes.Awaitable<U>)?) -> Promise<T | U>,
	read finally: (self: Promise<T>, onFinally: (() -> unknown)?) -> Promise<T>,
}

--[=[
	@within Promise
	@type PromiseThen<T> = <U, V>(self: Promise<T>, onFulfilled: ((value: T) -> Awaitable<U>)?, onRejected: ((reason: unknown) -> Awaitable<V>)?) -> Promise<U | V>

	The type of `Promise.prototype.then`. Luau reserves `then`, so the field is
	written `["then"]`, and it is read as `p["then"]` or `p.then_`.

	Each callback is optional. A callback that is missing, or not callable, is
	ignored, and the value or reason passes through to the derived promise.
]=]
export type PromiseThen<T> = <U, V>(
	self: Promise<T>,
	onFulfilled: ((value: T) -> esTypes.Awaitable<U>)?,
	onRejected: ((reason: unknown) -> esTypes.Awaitable<V>)?
) -> Promise<U | V>

--[=[
	@within Promise
	@type PromiseFulfilledResult<T> = { status: "fulfilled", value: T }

	One entry of the array returned by `Promise.allSettled` for a promise that
	fulfilled.
]=]

export type PromiseFulfilledResult<T> = { status: "fulfilled", value: T }
--[=[
	@within Promise
	@type PromiseRejectedResult = { status: "rejected", reason: unknown }

	One entry of the array returned by `Promise.allSettled` for a promise that
	rejected.
]=]

export type PromiseRejectedResult = { status: "rejected", reason: unknown }
--[=[
	@within Promise
	@type PromiseSettledResult<T> = PromiseFulfilledResult<T> | PromiseRejectedResult

	The result of one promise in `Promise.allSettled`. Check `status` to tell the two
	kinds apart.
]=]

export type PromiseSettledResult<T> = PromiseFulfilledResult<T> | PromiseRejectedResult

--[=[
	@within Promise
	@type PromiseWithResolvers<T> = { promise: Promise<T>, resolve: (value: Awaitable<T>) -> (), reject: (reason: unknown) -> () }

	The result of `Promise.withResolvers()`: a pending promise together with the
	functions that settle it.

	:::note
	`resolve` and `reject` share one "already resolved" flag. Only the first call
	of either one has any effect, and later calls are ignored, as in the spec.
	:::
]=]

export type PromiseWithResolvers<T> = {
	promise: Promise<T>,
	resolve: (value: esTypes.Awaitable<T>) -> (),
	reject: (reason: unknown) -> (),
}

--[=[
	@within Promise
	@type PromisePrototype = { ["then"]: PromiseThen<unknown>, then_: PromiseThen<unknown>, catch: ..., finally: ..., constructor: unknown? }

	The shape of `Promise.prototype`. Every promise reaches these methods through
	its `__index`. `constructor` is set to `Promise` once the module is loaded.
]=]

export type PromisePrototype = {
	read ["then"]: PromiseThen<unknown>,
	read then_: PromiseThen<unknown>,
	read catch: <U>(self: Promise<unknown>, onRejected: ((reason: unknown) -> esTypes.Awaitable<U>)?) -> Promise<unknown>,
	read finally: (self: Promise<unknown>, onFinally: (() -> unknown)?) -> Promise<unknown>,
	constructor: unknown?,
}

--[=[
	@within Promise
	@type PromiseStatic = { prototype: PromisePrototype, new: ..., resolve: ..., reject: ..., all: ..., allSettled: ..., any: ..., race: ..., withResolvers: ..., try: ..., __setScheduler: ..., __runJobs: ..., __setRejectionTracker: ..., __isPromise: ... }

	The shape of the table returned by this module, which is `Promise`.

	The fields `__setScheduler`, `__runJobs`, `__setRejectionTracker`, and
	`__isPromise` are host hooks, not JavaScript API. They are documented on the
	module. `__isPromise` is an internal brand check.
]=]

export type PromiseStatic = {
	read prototype: PromisePrototype,
	read new: <T>(executor: (resolve: (value: esTypes.Awaitable<T>) -> (), reject: (reason: unknown) -> ()) -> ()) -> Promise<T>,
	read resolve: <T>(value: esTypes.Awaitable<T>) -> Promise<T>,
	read reject: <T>(reason: unknown) -> Promise<T>,
	read all: <T>(values: esTypes.Array<esTypes.Awaitable<T>>) -> Promise<esTypes.Array<T>>,
	read allSettled: <T>(values: esTypes.Array<esTypes.Awaitable<T>>) -> Promise<esTypes.Array<PromiseSettledResult<T>>>,
	read any: <T>(values: esTypes.Array<esTypes.Awaitable<T>>) -> Promise<T>,
	read race: <T>(values: esTypes.Array<esTypes.Awaitable<T>>) -> Promise<T>,
	read withResolvers: <T>() -> PromiseWithResolvers<T>,
	read try: <T, A...>(callback: (A...) -> esTypes.Awaitable<T>, A...) -> Promise<T>,
	read __setScheduler: (((() -> ()) -> ())?) -> (),
	read __runJobs: () -> (),
	read __setRejectionTracker: (((promise: Promise<unknown>, reason: unknown) -> ())?) -> (),
	read __isPromise: (value: unknown) -> boolean,
}

type ResolveFn = (unknown) -> ()
type RejectFn = (unknown) -> ()
type Callback = (unknown) -> unknown
type Job = (unknown, unknown, unknown) -> ()

type Reaction = {
	capability: Promise<unknown>,
	handler: Callback?,
	isReject: boolean,
}

type Slot = {
	state: number,
	value: unknown,
	fulfillReactions: esTypes.Array<Reaction>?,
	rejectReactions: esTypes.Array<Reaction>?,
	handled: boolean, -- [[PromiseIsHandled]]
}

type InstanceMetatable = {
	read __index: PromisePrototype,
	read __tostring: (unknown) -> string,
}

--[=[
	@private

	Returns `true` for tables and userdata. In Luau, functions and other types are
	not objects, so they cannot have a `then` that adopts them.
]=]

const function isObject(value: unknown): boolean
	return type(value) == "table" or type(value) == "userdata"
end

--[=[
	@private

	Returns `true` for functions, and for tables with a `__call` metamethod.
]=]

const function isCallable(value: unknown): boolean
	if type(value) == "function" then
		return true
	end
	if type(value) == "table" then
		const metatable = getmetatable(value)
		return type(metatable) == "table" and rawget(metatable :: esTypes.Dictionary<unknown>, "__call") ~= nil
	end
	return false
end

--[=[
	@private

	Reads `value.then`. The read can throw, for example through a `__index`
	metamethod, so callers wrap it in `pcall`. A throw becomes a rejection, as in
	the spec's step for abrupt completion.
]=]

const function getThen(value: unknown): unknown
	return (value :: esTypes.Table<unknown, unknown>)["then"]
end

const function noop() end

const PENDING: number = 0
const FULFILLED: number = 1
const REJECTED: number = 2

const jobFns: esTypes.Array<Job> = {}
const jobA: esTypes.Array<unknown> = {}
const jobB: esTypes.Array<unknown> = {}
const jobC: esTypes.Array<unknown> = {}
local jobHead: number = 1
local jobTail: number = 0
local draining: boolean = false
local scheduled: boolean = false
local scheduler: ((() -> ()) -> ())? = nil

const slots: esTypes.Table<unknown, Slot> = setmetatable({} :: esTypes.Table<unknown, Slot>, { __mode = "k" })
local instanceMetatable: InstanceMetatable
local promisePrototype: PromisePrototype
local rejectionTracker: ((promise: Promise<unknown>, reason: unknown) -> ())? = nil
local pendingRejections: esTypes.Array<Promise<unknown>> = {}

-- Forward declarations: these are mutually recursive.
--[=[
	@private

	The promise resolution procedure. Resolving a promise with itself rejects it
	with a `TypeError`. A non-object fulfils the promise directly. A thenable is
	adopted in a later job, so the promise waits for it. Anything else fulfils the
	promise.
]=]

local resolvePromise: (Promise<unknown>, unknown) -> ()
--[=[
	@private

	Moves a pending promise to rejected, stores the reason, and queues its
	rejection reactions. If the promise has no handler yet, it is recorded so the
	rejection tracker can report it when the queue empties.

	Does nothing if the promise is already settled. The reason is stored as-is,
	without any adoption of thenables.
]=]

local rejectPromise: (Promise<unknown>, unknown) -> ()
--[=[
	@private

	Creates the `resolve`/`reject` pair for `promise`. They share one
	`alreadyResolved` flag, so only the first call of either takes effect (the
	spec's CreateResolvingFunctions).
]=]

local createResolvingFunctions: (Promise<unknown>) -> (ResolveFn, RejectFn)

--[=[
	@private

	Runs once per drain, after the queue is empty. It reports each rejection that
	still has no handler to `rejectionTracker`. This is the spec's
	HostPromiseRejectionTracker "reject" operation, with the "handle" case handled
	by re-checking `handled`.
]=]
const function processPendingRejections()
	if #pendingRejections == 0 then
		return
	end
	const list = pendingRejections
	pendingRejections = {}

	const tracker = rejectionTracker
	if tracker == nil then
		return
	end
	for _, promise in list do
		const slot = slots[promise]
		if slot ~= nil and not slot.handled then
			tracker(promise, slot.value)
		end
	end
end

--[=[
	@private

	Runs queued jobs in FIFO order until the queue is empty. Jobs queued during the
	drain run in the same drain, as microtasks do. A call made while a drain is
	already running returns immediately. Once the queue is empty, unhandled
	rejections are checked.

	:::note
	A job that throws stops the drain, and `draining` stays set. Errors from
	handlers and thenables are caught and turned into rejections, so this only
	affects a throwing rejection tracker.
	:::
]=]
const function drain()
	scheduled = false
	if draining then
		return
	end
	draining = true

	while jobHead <= jobTail do
		const index = jobHead
		const job = jobFns[index]
		const a, b, c = jobA[index], jobB[index], jobC[index]
		jobFns[index] = nil
		jobA[index] = nil
		jobB[index] = nil
		jobC[index] = nil
		jobHead = index + 1
		job(a, b, c)
	end

	jobHead = 1
	jobTail = 0
	draining = false

	processPendingRejections()
end

--[=[
	@private

	Adds a job to the FIFO queue. If the queue is not already being drained and a
	scheduler is installed, it asks the scheduler to run `drain`. Without a
	scheduler, jobs wait for `Promise.__runJobs()`.
]=]

const function enqueue(job: Job, a: unknown, b: unknown, c: unknown)
	const index = jobTail + 1
	jobTail = index
	jobFns[index] = job
	jobA[index] = a
	jobB[index] = b
	jobC[index] = c

	if not draining and not scheduled then
		const sched = scheduler
		if sched ~= nil then
			scheduled = true
			sched(drain)
		end
	end
end

--[=[
	@private

	Installs (or, with `nil`, removes) the host scheduler. If jobs are already
	waiting when a scheduler is installed, a drain is scheduled at once.
]=]

const function setScheduler(fn: ((() -> ()) -> ())?)
	scheduler = fn
	if fn ~= nil and jobHead <= jobTail and not draining and not scheduled then
		scheduled = true
		fn(drain)
	end
end

--[=[
	@private

	Implements `__tostring` for promises. It reports `[object Promise]`, with the
	state and value appended when the promise is settled. This is a Luau
	convenience, and JavaScript does not define this format.
]=]

const function promiseToString(self: unknown): string
	const slot = slots[self]
	if slot == nil then
		return "[object Promise]"
	end
	if slot.state == PENDING then
		return "[object Promise] <pending>"
	end
	if slot.state == FULFILLED then
		return "[object Promise] <fulfilled: " .. tostring(slot.value) .. ">"
	end
	return "[object Promise] <rejected: " .. tostring(slot.value) .. ">"
end

--[=[
	@private
	@within Promise
	@return Promise<T> -- a new pending promise with no reactions

	Creates a pending promise and records its state in the weak `slots` table.
]=]

const function newPromise<T>(): Promise<T>
	const promise = {} :: Promise<T>
	setmetatable(promise, instanceMetatable)
	slots[promise] = {
		state = PENDING,
		value = nil,
		fulfillReactions = nil,
		rejectReactions = nil,
		handled = false,
	}
	return promise
end

--[=[
	@private

	Runs one reaction job. A handler that is missing (or not callable) passes the
	value or reason through to the derived promise. Otherwise the handler runs
	under `pcall`, and its result or error settles the derived promise, following
	the spec's `PromiseReactionJob`.
]=]

const function runReactionJob(reaction: unknown, argument: unknown)
	const job = reaction :: Reaction
	const capability = job.capability
	const handler = job.handler

	-- A non-callable handler is treated as absent (PerformPromiseThen, step 3).
	if handler == nil or not isCallable(handler) then
		-- No handler: a fulfilment passes its value on, a rejection passes its reason on.
		if job.isReject then
			rejectPromise(capability, argument)
		else
			resolvePromise(capability, argument)
		end
		return
	end

	const ok, result = pcall(handler, argument)
	if ok then
		resolvePromise(capability, result)
	else
		rejectPromise(capability, result)
	end
end

const function triggerReactions(reactions: esTypes.Array<Reaction>, argument: unknown)
	for _, reaction in reactions do
		enqueue(runReactionJob, reaction, argument, nil)
	end
end

--[=[
	@private

	Moves a pending promise to fulfilled, stores the value, and queues its
	fulfilment reactions. Does nothing if the promise is already settled.
]=]

const function fulfillPromise(promise: Promise<unknown>, value: unknown)
	const slot = slots[promise]
	if slot.state ~= PENDING then
		return
	end

	const reactions = slot.fulfillReactions
	slot.state = FULFILLED
	slot.value = value
	slot.fulfillReactions = nil
	slot.rejectReactions = nil

	if reactions ~= nil then
		triggerReactions(reactions, value)
	end
end

function rejectPromise(promise: Promise<unknown>, reason: unknown)
	const slot = slots[promise]
	if slot.state ~= PENDING then
		return
	end

	const reactions = slot.rejectReactions
	slot.state = REJECTED
	slot.value = reason
	slot.fulfillReactions = nil
	slot.rejectReactions = nil

	if not slot.handled then
		-- Make sure a drain happens, so the rejection is checked at its end.
		if #pendingRejections == 0 then
			enqueue(noop, nil, nil, nil)
		end
		pendingRejections[#pendingRejections + 1] = promise
	end

	if reactions ~= nil then
		triggerReactions(reactions, reason)
	end
end

--[=[
	@private

	The spec's `NewPromiseResolveThenableJob`. It runs in a later job, calls the
	thenable's `then` with fresh resolving functions, and rejects the promise if
	that call throws.
]=]

const function resolveThenableJob(promise: unknown, thenable: unknown, thenFn: unknown)
	const resolve, reject = createResolvingFunctions(promise :: Promise<unknown>)
	const ok, reason = pcall(thenFn :: (unknown, ResolveFn, RejectFn) -> (), thenable, resolve, reject)
	if not ok then
		reject(reason)
	end
end

--[=[
	Creates the resolve/reject pair for `promise`. They share one
	`alreadyResolved` flag, so only the first call of either takes effect
	(the spec's CreateResolvingFunctions).
]=]
function createResolvingFunctions(promise: Promise<unknown>): (ResolveFn, RejectFn)
	local alreadyResolved: boolean = false

	const function resolve(resolution: unknown)
		if alreadyResolved then
			return
		end
		alreadyResolved = true
		resolvePromise(promise, resolution)
	end

	const function reject(reason: unknown)
		if alreadyResolved then
			return
		end
		alreadyResolved = true
		rejectPromise(promise, reason)
	end

	return resolve, reject
end

--[=[
	The promise resolution procedure: self-resolution is an error, a
	non-object fulfils directly, a thenable is adopted in a later job, and
	anything else fulfils.
]=]
function resolvePromise(promise: Promise<unknown>, resolution: unknown)
	if rawequal(resolution, promise) then
		rejectPromise(promise, TypeError.new("Chaining cycle detected for promise"))
		return
	end

	if not isObject(resolution) then
		fulfillPromise(promise, resolution)
		return
	end

	const ok, thenFn = pcall(getThen, resolution)
	if not ok then
		rejectPromise(promise, thenFn)
		return
	end

	if not isCallable(thenFn) then
		fulfillPromise(promise, resolution)
		return
	end

	enqueue(resolveThenableJob, promise, resolution, thenFn)
end

--[=[
	@private

	Attaches a fulfilment and a rejection reaction to a slot. A pending promise
	stores them. A settled promise queues the matching reaction at once. Either
	way, the promise is marked as handled.
]=]

const function performThen(slot: Slot, fulfillReaction: Reaction, rejectReaction: Reaction)
	const state: number = slot.state
	if state == PENDING then
		const fulfillList = slot.fulfillReactions or {}
		fulfillList[#fulfillList + 1] = fulfillReaction
		slot.fulfillReactions = fulfillList

		const rejectList = slot.rejectReactions or {}
		rejectList[#rejectList + 1] = rejectReaction
		slot.rejectReactions = rejectList
	elseif state == FULFILLED then
		enqueue(runReactionJob, fulfillReaction, slot.value, nil)
	else
		enqueue(runReactionJob, rejectReaction, slot.value, nil)
	end

	slot.handled = true
end

--[=[
	@within Promise
	@param self Promise<unknown> -- the promise to attach callbacks to
	@param onFulfilled ((value) -> Awaitable<U>)? -- called with the value on fulfilment
	@param onRejected ((reason) -> Awaitable<V>)? -- called with the reason on rejection
	@return Promise<U | V> -- the derived promise

	`Promise.prototype.then`. The callbacks run as microtasks. The derived promise
	takes the callback's return value, and it adopts that value if it is a
	thenable. If a callback throws, the derived promise rejects with the error.

	Non-callable callbacks are ignored, so the value or reason passes through.
	For example, `p.then_(p, 5)` behaves like `p.then_(p)`.

	:::caution
	Calling `then` on something that is not a promise throws a `TypeError`. It
	does not return a rejected promise.
	:::

	:::note
	`then` does not consult `Symbol.species`, because subclassing is not supported.
	The derived promise is always a base `Promise`.
	:::
]=]
const function promiseThen<U, V>(self: Promise<unknown>, onFulfilled: ((unknown) -> esTypes.Awaitable<U>)?, onRejected: ((unknown) -> esTypes.Awaitable<V>)?): Promise<U | V>
	const slot: Slot? = if isObject(self) then slots[self] else nil
	if slot == nil then
		error(TypeError.new("Promise.prototype.then called on a non-Promise receiver"))
	end

	const derived = newPromise<<U | V>>() :: Promise<unknown>
	const fulfillReaction: Reaction = {
		capability = derived,
		handler = if isCallable(onFulfilled) then onFulfilled :: Callback else nil,
		isReject = false,
	}
	const rejectReaction: Reaction = {
		capability = derived,
		handler = if isCallable(onRejected) then onRejected :: Callback else nil,
		isReject = true,
	}

	performThen(slot, fulfillReaction, rejectReaction)
	return derived :: Promise<U | V>
end

--[=[
	@private

	Calls `target.then(onFulfilled, onRejected)` through a property lookup (the
	spec's `Invoke`). A user-defined `then` is therefore honoured by `catch`,
	`finally`, the combinators, and adoption. Throws a `TypeError` if the receiver
	is not an object or `then` is not callable.
]=]
local function invokeThen(target: unknown, onFulfilled: unknown, onRejected: unknown): unknown
	if not isObject(target) then
		error(TypeError.new("Promise: receiver is not an object"))
	end
	const thenFn = (target :: esTypes.Table<unknown, unknown>)["then"]
	if not isCallable(thenFn) then
		error(TypeError.new("Promise: 'then' is not a function"))
	end
	return (thenFn :: (unknown, unknown, unknown) -> unknown)(target, onFulfilled, onRejected)
end

--[=[
	@within Promise
	@param value Awaitable<T> -- a plain value, a promise, or a thenable
	@return Promise<T> -- a promise that settles like `value`

	`Promise.resolve(value)`.

	If `value` is a native promise whose `constructor` is `Promise`, `value` itself
	is returned. Otherwise a new promise is created and resolved with `value`, so
	thenables are adopted. If reading `then` throws, the new promise rejects with
	that error.

	:::note
	The identity check uses the `constructor` property, as in the spec. A
	promise-like object that is not produced by this module is wrapped, not
	returned as-is.
	:::
]=]
const function promiseResolve<T>(value: esTypes.Awaitable<T>): Promise<T>
	if isObject(value) and slots[value] ~= nil and rawequal((value :: esTypes.Table<unknown, unknown>)["constructor"], promisePrototype.constructor) then
		return value :: Promise<T>
	end
	const promise = newPromise<<T>>()
	resolvePromise(promise :: Promise<unknown>, value)
	return promise
end

--[=[
	@private

	`true` if `value` is a promise created by this module. This is the brand check
	used by `Promise.__isPromise`.
]=]

const function isPromise(value: unknown): boolean
	return isObject(value) and slots[value] ~= nil
end

--[=[
	@within Promise
	@param self unknown -- the promise to attach to
	@param onRejected ((reason) -> Awaitable<U>)? -- called with the reason on rejection
	@return Promise<unknown> -- the derived promise

	`Promise.prototype.catch(onRejected)`. Equivalent to `then(nil, onRejected)`,
	and it reaches `then` through `invokeThen`.

	If the promise fulfils, the value passes through. If it rejects, `onRejected`
	runs and its result becomes the value of the derived promise.
]=]

const function catchImpl<U>(self: unknown, onRejected: ((unknown) -> esTypes.Awaitable<U>)?): Promise<unknown>
	return invokeThen(self, nil, onRejected) :: Promise<unknown>
end

--[=[
	@within Promise
	@param self unknown -- the promise to attach to
	@param onFinally (() -> unknown)? -- called with no arguments on either outcome
	@return Promise<unknown> -- the derived promise

	`Promise.prototype.finally(onFinally)`. `onFinally` runs with no arguments when
	the promise settles, whatever the outcome.

	The original value or reason passes through, unless `onFinally` throws or
	returns a promise that rejects. In that case the derived promise rejects with
	that error or reason instead.

	If the result of `onFinally` is a promise, it is awaited before the original
	outcome is passed on, as in JavaScript. A missing or non-callable `onFinally`
	passes the outcome through unchanged.
]=]
const function finallyImpl(self: unknown, onFinally: (() -> unknown)?): Promise<unknown>
	if not isCallable(onFinally) then
		return invokeThen(self, onFinally, onFinally) :: Promise<unknown>
	end
	const callback = onFinally :: () -> unknown

	const function thenFinally(value: unknown): unknown
		const result = callback()
		return invokeThen(promiseResolve(result), function()
			return value
		end, nil)
	end

	const function catchFinally(reason: unknown): unknown
		const result = callback()
		return invokeThen(promiseResolve(result), function()
			error(reason, 0)
		end, nil)
	end

	return invokeThen(self, thenFinally, catchFinally) :: Promise<unknown>
end

--[=[
	@within Promise
	@private

	`Promise.prototype`. It is the `__index` of every promise, so it is the only
	place where `then`, `then_`, `catch`, and `finally` live.

	It is frozen once the module is loaded. The `prototype` and `Promise` tables
	are cast with `:: PromisePrototype` and `:: PromiseStatic`. Without the casts,
	the analyzer reports identical-looking mismatches on the generic functions.
]=]

const prototype = {
	["then"] = promiseThen,
	then_ = promiseThen,
	catch = catchImpl,
	finally = finallyImpl,
} :: PromisePrototype

promisePrototype = prototype
instanceMetatable = table.freeze {
	__index = prototype,
	__tostring = promiseToString,
}

--[=[
	@within Promise
	@param executor (resolve, reject) -> () -- runs synchronously with the two resolving functions
	@return Promise<T> -- the new promise

	`new Promise(executor)`. Creates a pending promise and runs `executor`
	synchronously, passing the resolving functions as arguments.

	If `executor` throws before the promise is settled, the promise rejects with
	that error. If it has already resolved, the error is ignored, as in the spec.

	:::caution
	A non-callable `executor` throws a `TypeError` synchronously, as in
	JavaScript. It does not return a rejected promise.
	:::
]=]
const function newImpl<T>(executor: (resolve: (esTypes.Awaitable<T>) -> (), reject: (unknown) -> ()) -> ()): Promise<T>
	if not isCallable(executor) then
		error(TypeError.new("Promise resolver is not a function"))
	end

	const promise = newPromise<<T>>()
	const resolve, reject = createResolvingFunctions(promise :: Promise<unknown>)
	const ok, reason = pcall(executor, resolve, reject)
	if not ok then
		reject(reason)
	end
	return promise
end

--[=[
	@within Promise
	@param reason unknown -- the rejection reason, stored as-is
	@return Promise<T> -- a promise rejected with `reason`

	`Promise.reject(reason)`. The reason is not adopted, so a promise or thenable
	passed as `reason` stays as the reason itself. This matches the spec.
]=]

const function rejectImpl<T>(reason: unknown): Promise<T>
	const promise = newPromise<<T>>()
	rejectPromise(promise :: Promise<unknown>, reason)
	return promise
end

--[=[
	@within Promise
	@return PromiseWithResolvers<T> -- `{ promise, resolve, reject }`

	`Promise.withResolvers()`. Returns a pending promise together with the functions
	that settle it. Its `resolve` adopts thenables in the same way as
	`Promise.resolve`.

	The two functions are first-wins: only the first call of either one has an
	effect.
]=]

const function withResolvers<T>(): PromiseWithResolvers<T>
	const promise = newPromise<<T>>()
	const resolve, reject = createResolvingFunctions(promise :: Promise<unknown>)
	return { promise = promise, resolve = resolve, reject = reject }
end

--[=[
	@private

	Shared driver for the combinators. It creates the result promise, checks that
	the argument is a table, and runs the worker under `pcall`. If the worker
	throws, the result promise rejects with that error.

	A non-table argument gives a promise rejected with a `TypeError`, not a thrown
	error. The workers are module-level functions, so each call only allocates the
	result promise and its resolving functions.
]=]
const function runCombinator<R>(worker: (ResolveFn, RejectFn, esTypes.Array<unknown>) -> (), iterable: unknown): Promise<R>
	const promise = newPromise<<R>>()
	const resolve, reject = createResolvingFunctions(promise :: Promise<unknown>)
	if type(iterable) ~= "table" then
		reject(TypeError.new("Promise combinator argument is not iterable"))
		return promise
	end

	const ok, reason = pcall(worker, resolve, reject, iterable :: esTypes.Array<unknown>)
	if not ok then
		reject(reason)
	end
	return promise
end

--[=[
	@private

	The worker for `Promise.all`. Each element is resolved with `Promise.resolve`
	and attached through `invokeThen`. The first rejection rejects the result.
	When all elements have fulfilled, the result fulfils with the values in input
	order. An empty array fulfils immediately with `{}`.
]=]

const function allWorker(resolve: ResolveFn, reject: RejectFn, iterable: esTypes.Array<unknown>)
	const count = #iterable
	const values: esTypes.Array<unknown> = table.create(count)
	local remaining = 1

	for index = 1, count do
		local called = false
		remaining += 1
		invokeThen(
			promiseResolve(iterable[index]),
			function(value: unknown)
				if called then
					return
				end
				called = true
				values[index] = value
				remaining -= 1
				if remaining == 0 then
					resolve(values)
				end
			end,
			reject
		)
	end

	remaining -= 1
	if remaining == 0 then
		resolve(values)
	end
end

--[=[
	@private

	The worker for `Promise.allSettled`. Every element is recorded as
	`{ status = "fulfilled", value }` or `{ status = "rejected", reason }`. The
	result fulfils once all elements have settled, and it never rejects because of
	an element. An empty array fulfils immediately with `{}`.
]=]

const function allSettledWorker(resolve: ResolveFn, reject: RejectFn, iterable: esTypes.Array<unknown>)
	const count = #iterable
	const results: esTypes.Array<PromiseSettledResult<unknown>> = {}
	local remaining: number = 1

	for index = 1, count do
		local called = false
		remaining += 1

		const function settle(result: PromiseSettledResult<unknown>)
			if called then
				return
			end
			called = true
			results[index] = result
			remaining -= 1
			if remaining == 0 then
				resolve(results)
			end
		end

		invokeThen(
			promiseResolve(iterable[index]),
			function(value: unknown)
				settle({ status = "fulfilled", value = value })
			end,
			function(reason: unknown)
				settle({ status = "rejected", reason = reason })
			end
		)
	end

	remaining -= 1
	if remaining == 0 then
		resolve(results)
	end
end

--[=[
	@private

	The worker for `Promise.any`. The first fulfilment resolves the result. Once
	every element has rejected, the result rejects with an `AggregateError`. That
	error holds the reasons in input order, with the message
	`"All promises were rejected"`. An empty array rejects at once with an empty
	`AggregateError`.
]=]

const function anyWorker(resolve: ResolveFn, reject: RejectFn, iterable: esTypes.Array<unknown>)
	const count = #iterable
	const reasons: esTypes.Array<unknown> = table.create(count)
	local remaining: number = 1

	for index = 1, count do
		local called = false
		remaining += 1
		invokeThen(
			promiseResolve(iterable[index]),
			resolve,
			function(reason: unknown)
				if called then
					return
				end
				called = true
				reasons[index] = reason
				remaining -= 1
				if remaining == 0 then
					reject(AggregateError.new(reasons, "All promises were rejected"))
				end
			end
		)
	end

	remaining -= 1
	if remaining == 0 then
		reject(AggregateError.new(reasons, "All promises were rejected"))
	end
end

--[=[
	@private

	The worker for `Promise.race`. The first element to settle settles the result.
	An empty array never settles.
]=]

const function raceWorker(resolve: ResolveFn, reject: RejectFn, iterable: esTypes.Array<unknown>)
	for index = 1, #iterable do
		invokeThen(promiseResolve(iterable[index]), resolve, reject)
	end
end

--[=[
	@within Promise
	@param callback (...A) -> Awaitable<T> -- called synchronously with the extra arguments
	@param ... A -- arguments passed to `callback`
	@return Promise<T> -- settles with what `callback` returns or throws

	`Promise.try(callback, ...)`. This is an ES2025 addition. Calls `callback`
	synchronously with the given arguments. The promise fulfils with its return
	value, which is adopted if it is a thenable. It rejects with the error if the
	call throws.

	A non-callable `callback` gives a promise rejected with a `TypeError`, not a
	thrown error.
]=]
const function tryImpl<T, A...>(callback: (A...) -> esTypes.Awaitable<T>, ...: A...): Promise<T>
	const promise = newPromise<<T>>()
	if not isCallable(callback) then
		rejectPromise(promise :: Promise<unknown>, TypeError.new("Promise.try: callback is not a function"))
		return promise
	end

	const ok, result = pcall(callback, ...)
	if ok then
		resolvePromise(promise :: Promise<unknown>, result)
	else
		rejectPromise(promise :: Promise<unknown>, result)
	end
	return promise
end

--[=[
	@within Promise
	@param values Array<Awaitable<T>> -- plain values and/or promises
	@return Promise<Array<T>> -- resolves with the values in input order

	`Promise.all(values)`. Fulfils with an array of the values once every input has
	fulfilled, in input order. Rejects with the first rejection.

	:::caution
	If the inputs mix plain values and promises, pass the type argument explicitly
	(`Promise.all<number>(...)`). See the type-inference caution at the top of the
	module.
	:::
]=]

const function allImpl<T>(values: esTypes.Array<esTypes.Awaitable<T>>): Promise<esTypes.Array<T>>
	return runCombinator<<esTypes.Array<T>>>(allWorker, values)
end

--[=[
	@within Promise
	@param values Array<Awaitable<T>> -- plain values and/or promises
	@return Promise<Array<PromiseSettledResult<T>>> -- one settlement record per input

	`Promise.allSettled(values)`. Waits for every input to settle, then fulfils
	with one record per input, in input order. The records are
	`PromiseFulfilledResult` or `PromiseRejectedResult`. It never rejects because of
	an input.
]=]

const function allSettledImpl<T>(values: esTypes.Array<esTypes.Awaitable<T>>): Promise<esTypes.Array<PromiseSettledResult<T>>>
	return runCombinator<<esTypes.Array<PromiseSettledResult<T>>>>(allSettledWorker, values)
end

--[=[
	@within Promise
	@param values Array<Awaitable<T>> -- plain values and/or promises
	@return Promise<T> -- fulfils with the first fulfilment

	`Promise.any(values)`. Fulfils with the first input to fulfil. If every input
	rejects, or the array is empty, it rejects with an `AggregateError` that holds
	the reasons in input order.
]=]

const function anyImpl<T>(values: esTypes.Array<esTypes.Awaitable<T>>): Promise<T>
	return runCombinator<<T>>(anyWorker, values)
end

--[=[
	@within Promise
	@param values Array<Awaitable<T>> -- plain values and/or promises
	@return Promise<T> -- settles like the first input to settle

	`Promise.race(values)`. Settles the same way as the first input to settle, whether
	it fulfils or rejects. An empty array gives a promise that never settles, as in
	the spec.
]=]

const function raceImpl<T>(values: esTypes.Array<esTypes.Awaitable<T>>): Promise<T>
	return runCombinator<<T>>(raceWorker, values)
end

--[=[
	@within Promise
	@prop prototype PromisePrototype

	The module. It exposes the constructor-style `new`, the statics, and
	`prototype`. It is frozen, so it cannot be extended from outside.

	`Symbol.species` is set to `Promise`. `Symbol.toStringTag` on the prototype is
	`"Promise"`, so `tostring` and `Object.prototype.toString` report
	`[object Promise]`.
]=]

const Promise = {
	prototype = prototype,
	new = newImpl,
	resolve = promiseResolve,
	reject = rejectImpl,
	all = allImpl,
	allSettled = allSettledImpl,
	any = anyImpl,
	race = raceImpl,
	withResolvers = withResolvers,
	try = tryImpl,

	-- Host hooks (see the class docs).
	__setScheduler = setScheduler,
	__runJobs = drain,
	__setRejectionTracker = function(tracker: ((promise: Promise<unknown>, reason: unknown) -> ())?)
		rejectionTracker = tracker
	end,

	-- `isPromise` is kept internal but is useful to hosts that need a brand check.
	__isPromise = isPromise,
} :: PromiseStatic

prototype.constructor = Promise
const taggable = prototype :: esTypes.Table<unknown, unknown>
taggable[Symbol.toStringTag] = "Promise"
const statics = Promise :: esTypes.Table<unknown, unknown>
statics[Symbol.species] = Promise

table.freeze(prototype)
table.freeze(Promise)

return Promise
