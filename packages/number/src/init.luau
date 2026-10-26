--!strict

--[=[
	@class Number

	A Luau port of JavaScript's [`Number`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number)
	namespace: its static properties (`EPSILON`, `MAX_SAFE_INTEGER`,
	...), static methods (`isInteger`, `parseInt`, ...), a
	`Number.prototype` sub-table holding the instance methods
	(`toFixed`, `toString`, ...), and a constructor: calling
	`Number(value)` itself.

	:::note
	`Number(value)` returns a plain, primitive Luau `number` — matching
	real JavaScript's *bare* `Number(value)` call (as opposed to
	`new Number(value)`, which produces a boxed object). There is no
	boxed-instance mode in this library at all: an earlier version of
	this module experimented with one (modelled after `new Number(x)`),
	but it was dropped in favour of this simpler, more broadly useful
	behaviour — matching how this library's `Boolean` already works
	(see `Boolean`'s class-level docs for the parallel reasoning there),
	and matching what most calling code actually wants from
	`Number(...)` in practice.
	:::

	:::caution
	Since `Number(value)` returns a plain `number`, its result can
	never be the receiver of `Number.prototype`'s methods via `:` syntax
	(`Number(value):toFixed(2)` does not work — see the caution on
	`Number.prototype` for why no Luau number ever can be). Call
	`Number.prototype.toFixed(Number(value), 2)` directly instead.
	:::

	:::note
	Locale-aware formatting (`toLocaleString`) is intentionally not
	implemented — it depends on locale data (number grouping, decimal
	separators, currency symbols, ...) with no standard source of truth
	in Luau, unlike a browser's or Node's ICU-backed implementation.
	:::

	:::note
	Both `Number` and `Number.prototype` are frozen with `table.freeze`
	before being returned, making the whole public surface immutable —
	no new static members can be added, and none of the existing ones
	(including `prototype` itself) can be reassigned. `table.freeze`
	never replaces a table with a different object and never touches an
	already-installed metatable, so this `Number(value)` constructor
	(wired up via `__call` below) keeps working normally after freezing.
	:::
]=]

const __staticProps = require("@self/__staticProps")
const __toNumber = require("@self/__toNumber")
const prototype = require("@self/prototype")

const Number = {
	EPSILON = __staticProps.EPSILON,
	MAX_SAFE_INTEGER = __staticProps.MAX_SAFE_INTEGER,
	MIN_SAFE_INTEGER = __staticProps.MIN_SAFE_INTEGER,
	MAX_VALUE = __staticProps.MAX_VALUE,
	MIN_VALUE = __staticProps.MIN_VALUE,
	NaN = __staticProps.NAN,
	POSITIVE_INFINITY = __staticProps.POSITIVE_INFINITY,
	NEGATIVE_INFINITY = __staticProps.NEGATIVE_INFINITY,

	__toNumber = __toNumber,
	isInteger = require("@self/isInteger"),
	isFinite = require("@self/isFinite"),
	isNaN = require("@self/isNaN"),
	isSafeInteger = require("@self/isSafeInteger"),
	parseFloat = require("@self/parseFloat"),
	parseInt = require("@self/parseInt"),

	prototype = prototype,
}

--[=[
	@within Number
	@function __call
	@param value any? -- the value to coerce
	@return number -- `value` coerced to a primitive number via `ToNumber`

	`Number(value)` coerces `value` the same way JavaScript's internal
	`ToNumber` would (see the internal `__toNumber` module for the exact
	rules, including its documented `nil`/`undefined` caveat).

	Calling with zero arguments (`Number()`) yields `0`, matching JS.
]=]
setmetatable(Number, {
	__call = function(_, ...): number
		const argumentCount: number = select("#", ...)
		if argumentCount == 0 then
			return 0
		end
		return __toNumber(...)
	end,
})

table.freeze(Number)

return Number
