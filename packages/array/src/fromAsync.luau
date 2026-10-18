--!strict

--[=[
	@class fromAsync

	A Luau implementation of JavaScript's [`Array.fromAsync()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/fromAsync).
]=]

const ECMAScript = require "../ECMAScript"
const Promise = require "../Promise"
const Symbol = require "../Symbol"
const TypeError = require "../Error" .TypeError
const esTypes = require "../ES17-Types"
const isArray = require "./isArray"

type Step = { done: boolean, value: unknown }

const function nextOf(iterator: esTypes.Table<unknown, unknown>): unknown
	return (iterator["next"] :: (unknown) -> unknown)(iterator)
end

-- Turns a raw `next()` result into a promise of a `Step`. The `value` is
-- awaited only when `awaitValue` is set (sync iterators and array-likes).
const function toStep(raw: unknown, awaitValue: boolean): Promise.Promise<Step>
	const promise = Promise.resolve(raw)
	return promise.then_(promise, function(record: unknown): Promise.Promise<Step>
		const fields = record :: esTypes.Table<unknown, unknown>
		const done = if fields["done"] then true else false
		if done or not awaitValue then
			return Promise.resolve({ done = done, value = fields["value"] } :: Step)
		end
		const valuePromise = Promise.resolve(fields["value"])
		return valuePromise.then_(valuePromise, function(value: unknown): Step
			return { done = false, value = value }
		end, nil)
	end, nil)
end

--[=[
	@within fromAsync
	@param items unknown -- an async iterable, an iterable, or an array-like
	@param mapFn ((value: unknown, index: number) -> Awaitable<U>)? -- applied to each element
	@return Promise<Array<U>> -- settles with the collected array

	`Array.fromAsync(items, mapFn?)`. Collects the values one at a time and returns
	a promise for the array.

	- An async iterable (`[Symbol.asyncIterator]`) is read with `await next()`.
	  Its values are used as they are.
	- A sync iterable or array-like has each value awaited first.
	- `mapFn` results are awaited too.

	If anything throws, or a value rejects, the result rejects with that reason.
	`undefined` items reject with a `TypeError`.

	:::caution
	Like `from`, this returns `Array<U>` and cannot check the element type.
	:::
]=]
const function fromAsync(items: unknown, mapFn: ((value: unknown, index: number) -> unknown)?): Promise.Promise<esTypes.Array<unknown>>
	return Promise.new<<esTypes.Array<unknown>>>(function(resolve, reject)
		if items == nil then
			reject(TypeError.new("Array.fromAsync: undefined is not async iterable or iterable"))
			return
		end

		const result: esTypes.Array<unknown> = {}
		local count: number = 0
		local readNext: () -> Promise.Promise<Step>

		if type(items) == "string" then
			const characters: esTypes.Array<string> = {}
			local length = 0
			for _, codepoint in utf8.codes(items :: string) do
				length += 1
				characters[length] = utf8.char(codepoint)
			end
			local index = 0
			readNext = function()
				if index >= length then
					return Promise.resolve({ done = true, value = nil } :: Step)
				end
				index += 1
				return toStep({ value = characters[index] }, true)
			end
		elseif type(items) == "table" then
			const object = items :: esTypes.Table<unknown, unknown>
			const asyncFn = object[Symbol.asyncIterator]
			const syncFn = object[Symbol.iterator]
			if ECMAScript.IsCallable(asyncFn) then
				const iterator = (asyncFn :: (unknown) -> unknown)(items) :: esTypes.Table<unknown, unknown>
				readNext = function()
					return toStep(nextOf(iterator), false)
				end
			elseif ECMAScript.IsCallable(syncFn) then
				const iterator = (syncFn :: (unknown) -> unknown)(items) :: esTypes.Table<unknown, unknown>
				readNext = function()
					return toStep(nextOf(iterator), true)
				end
			else
				-- Arrays use 1-based storage; array-likes use a 0-based `length` protocol.
				const isList = isArray(items)
				const length = if isList then #object else ECMAScript.ToLength(object["length"])
				const offset = if isList then 1 else 0
				local index = 0
				readNext = function()
					if index >= length then
						return Promise.resolve({ done = true, value = nil } :: Step)
					end
					const current = index
					index += 1
					return toStep({ value = object[current + offset] }, true)
				end
			end
		else
			-- Numbers and booleans have no elements.
			resolve(result)
			return
		end

		local function pump()
			local ok, nextPromise = pcall(readNext)
			if not ok then
				reject(nextPromise)
				return
			end

			nextPromise.then_(nextPromise, function(step: Step)
				if step.done then
					resolve(result)
					return nil
				end

				const index = count
				count += 1
				if mapFn == nil then
					result[index + 1] = step.value
					pump()
					return nil
				end

				const callback = mapFn
				local mapOk, mapped = pcall(callback, step.value, index)
				if not mapOk then
					reject(mapped)
					return nil
				end

				const mappedPromise = Promise.resolve(mapped)
				mappedPromise.then_(mappedPromise, function(value: unknown)
					result[index + 1] = value
					pump()
					return nil
				end, function(reason: unknown)
					reject(reason)
					return nil
				end)
				return nil
			end, function(reason: unknown)
				reject(reason)
				return nil
			end)
		end

		pump()
	end)
end

return fromAsync
