--!strict

--[=[
	@class __helpers
	@private

	Internal helpers shared by the `Array` modules. Not part of the public API.

	Number conversion and formatting come from `Number`, not from here. Only the
	array-specific helpers and the `ToIntegerOrInfinity` operation live here, because
	`Number` does not export that operation.

	:::note
	Keep helpers small. Logic used by a single method lives in that method's file.
	:::
]=]

const String = require("../String")
const Symbol = require("../Symbol")
const esTypes = require("../ES17-Types")
const isArray = require("./isArray")

--[=[
	@within Array
	@type IteratorResult<T> = { value: T?, done: boolean }

	The record returned by `ArrayIterator.next`. When `done` is `true`, `value`
	is `nil`.
]=]
export type IteratorResult<T> = {
	value: T?,
	done: boolean,
}

--[=[
	@within Array
	@type ArrayIterator<T> = { next: (self: ArrayIterator<T>) -> IteratorResult<T> }

	An iterator returned by `values`, `keys`, and `entries`. Step it with
	`it.next(it)`. The iterator is also its own `[Symbol.iterator]`, so it can be
	passed anywhere an iterable is accepted.

	:::note
	This is not a Luau generic `for` iterator. Use a `while` loop over `next`.
	:::
]=]
export type ArrayIterator<T> = {
	next: (self: ArrayIterator<T>) -> IteratorResult<T>,
}

--[=[
	@private

	Converts an element to a string the way `String(value)` does. Arrays join with
	`","`, and other tables give `"[object Object]"`. `seen` holds the arrays being
	joined, so a cycle becomes an empty string.
]=]
local joinValues: (esTypes.Array<unknown>, string, esTypes.Table<unknown, boolean>?) -> string

--[=[
	@private

	Joins an array with `separator`, the way `Array.prototype.join` does. `nil`
	elements become `""`. An array that is already being joined further up the
	stack becomes `""`, which breaks cycles as JS does.
]=]
joinValues = function(array: esTypes.Array<unknown>, separator: string, seen: esTypes.Table<unknown, boolean>?): string
	const visited: esTypes.Table<unknown, boolean> = seen or {}
	if visited[array] then
		return ""
	end
	visited[array] = true

	const count = #array
	const parts: esTypes.Array<string> = table.create(count, "")
	for index = 1, count do
		const element = array[index]
		if element == nil then
			parts[index] = ""
		elseif type(element) == "table" and isArray(element) then
			-- Nested arrays join recursively, so `[[]]` gives `""`, as in JS.
			parts[index] = joinValues(element :: esTypes.Array<unknown>, ",", visited)
		else
			parts[index] = String(element)
		end
	end

	visited[array] = nil
	return table.concat(parts, separator)
end

--[=[
	@private

	A stable merge sort over a copy of `values`, which must hold no `nil`s.
	`compare(a, b)` returns a negative number when `a` sorts before `b`. Equal
	elements keep their input order, as `Array.prototype.sort` requires since ES2019.
]=]
const function stableSort<T>(values: esTypes.Array<T>, compare: (T, T) -> number): esTypes.Array<T>
	const count = #values
	local source: esTypes.Array<T> = table.move(values, 1, count, 1, {})
	local buffer: esTypes.Array<T> = table.create(count)

	local width = 1
	while width < count do
		local start = 1
		while start <= count do
			const middle = math.min(start + width, count + 1)
			const finish = math.min(start + 2 * width, count + 1)
			local left, right, out = start, middle, start

			while left < middle and right < finish do
				-- Take from the right only when it is strictly smaller, to stay stable.
				if compare(source[right], source[left]) < 0 then
					buffer[out] = source[right]
					right += 1
				else
					buffer[out] = source[left]
					left += 1
				end
				out += 1
			end
			if left < middle then
				table.move(source, left, middle - 1, out, buffer)
				out += middle - left
			end
			if right < finish then
				table.move(source, right, finish - 1, out, buffer)
			end

			start += 2 * width
		end
		source, buffer = buffer, source
		width *= 2
	end

	return source
end

--[=[
	@private

	Appends the elements of `source` to `target`, flattening nested arrays up to
	`depth` levels. `length` is the current length of `target`. Returns the new length.
]=]
const function flattenInto(
	target: esTypes.Array<unknown>,
	length: number,
	source: esTypes.Array<unknown>,
	depth: number
): number
	local next = length
	for index = 1, #source do
		const element = source[index]
		if depth > 0 and isArray(element) then
			next = flattenInto(target, next, element :: esTypes.Array<unknown>, depth - 1)
		else
			next += 1
			target[next] = element
		end
	end
	return next
end

--[=[
	@private

	Builds an `ArrayIterator` from `step`. `step` returns `(done, value)` and is
	called once per `next`. It reads the array's current length on every call, so
	the iterator sees later changes, as JS array iterators do.
]=]
const function makeIterator<T>(step: () -> (boolean, T?)): ArrayIterator<T>
	const function nextFn(_self: ArrayIterator<T>): IteratorResult<T>
		const done, value = step()
		return { value = value, done = done }
	end

	const raw: esTypes.Table<unknown, unknown> = { next = nextFn }
	raw[Symbol.iterator] = function(self: unknown): unknown
		return self
	end
	return raw :: ArrayIterator<T>
end

return {
	joinValues = joinValues,
	stableSort = stableSort,
	flattenInto = flattenInto,
	makeIterator = makeIterator,
}
