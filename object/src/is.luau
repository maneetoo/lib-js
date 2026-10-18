--!strict

--[=[
	@class is
	A Luau implementation of JavaScript's [`Object.is()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is).

	Determines whether two values are the *same value*, using the
	[SameValue](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is#description)
	algorithm rather than Luau's native `==` equality. The two differ in
	exactly two cases:

	- `NaN` is considered equal to itself (whereas `NaN == NaN` is
	  `false` under `==`).
	- `+0` and `-0` are considered *different* (whereas `+0 == -0` is
	  `true` under `==`).
      
	In every other case — primitives, strings, booleans, `nil`, and
	table/`userdata`/`function` references compared by identity — the
	result matches `==`.
]=]

const Number = require "../Number"

--[=[
	@within is
	@param value1 T -- the first value to compare
	@param value2 V -- the second value to compare
	@return boolean -- `true` if the two values are the same under the
		SameValue algorithm

	Returns `true` when `value1` and `value2` are the same value, and
	`false` otherwise.

	:::caution
	Reference types (tables, `userdata`, functions, `thread`) are compared
	by identity, not structurally — the same semantics as Luau's `==`.
	There is no deep-equality mode here; if you need structural
	comparison, walk the tables yourself (and decide how you want to
	handle cycles, metatables with `__eq`, and reference-vs-value fields
	inside).
	:::
]=]
const function is<T, V>(value1: T, value2: V): boolean
	if Number.isNaN(value1) and Number.isNaN(value2) then
		return true
	end

	if type(value1) == "number" and type(value2) == "number" then
		if value1 == 0 and value2 == 0 then
			return (1 / (value1 :: number)) == (1 / (value2 :: number))
		end
	end

	return value1 == value2
end

return is
