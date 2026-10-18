--!strict

--[=[
	@class Array

	A Luau port of JavaScript's
	[`Array`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array),
	following the ES2025 specification as closely as Luau allows.

	Unlike `Object`, this is a folder: each method is its own file under
	`prototype/`, and each static is its own file here. The module is `Array`, and
	`Array.prototype` holds the methods.

	```lua
	local Array = require(path.to.Array)

	local doubled = Array.prototype.map({ 1, 2, 3 }, function(value)
		return value * 2
	end)
	-- doubled is { 2, 4, 6 }
	```

	:::note
	Each method takes the array as its first argument: `Array.prototype.push(arr, x)`.
	Arrays are plain tables with no metatable, so there is no `arr:push(x)` form.
	:::

	:::caution
	Arrays are plain Luau tables `{ T }`, indexed from `1`. The methods use 0-based
	JS indices for their arguments and results, so `indexOf` returns `0` for the first
	element. But `arr[1]` is still the first element when you index the table
	directly.
	:::

	:::caution
	There are no holes. `undefined` is `nil`, and a `nil` element cannot be told
	apart from a missing one. The length is `#arr`, so a trailing `undefined`
	does not count. `new Array(n)` therefore gives length `0`. See `__toArray` for details.
	:::

	:::caution
	`isArray` is a heuristic. It counts any table whose keys are all positive
	integers, so `{}` is an array. A plain object table with only integer keys is
	indistinguishable from an array.
	:::

	:::caution
	There is no `thisArg`. Luau functions have no `this`, so callbacks are called
	with `(value, index, array)` only. Use a closure to capture context.
	:::

	:::caution
	Callback `index` values are 0-based, as in JS, and the `array` argument is the
	same table that was passed in.
	:::

	:::caution
	`Symbol.species` is `Array`. Subclassing is not supported, so `species` is
	never consulted.
	:::

	:::caution
	Numbers that are not integers are converted to strings with Luau `tostring`,
	which uses `%.14g`. So `0.1 + 0.2` becomes `"0.3"` rather than JS's
	`"0.30000000000000004"`.
	:::

	:::caution
	The default `sort` compares strings by UTF-8 byte order. For ASCII this
	matches JS. For characters above U+FFFF it can differ from JS's UTF-16 code
	unit order when compared with characters from U+E000 to U+FFFF.
	:::

	:::note
	`values`, `keys`, and `entries` return iterators with a `next(self)` method. They
	are not Luau generic-`for` iterators. Step them with a `while` loop.
	:::

	:::note
	This module needs `../Symbol` to provide `iterator`, `asyncIterator`,
	`species`, and `unscopables`, and `../Promise` for `fromAsync`.
	:::
]=]

const esTypes = require "./ES17-Types"
const Symbol = require "./Symbol"
const prototype = require "@self/prototype"
const __toArray = require "@self/__toArray"

const Array = {
    __toArray = __toArray,
    of = require "@self/of",
    from = require "@self/from",
    fromAsync = require "@self/fromAsync",
    isArray = require "@self/isArray",

	prototype = prototype,
}

const taggable = Array :: esTypes.Table<unknown, unknown>
taggable[Symbol.species] = Array
const prototypeTable = prototype :: esTypes.Table<unknown, unknown>
prototypeTable.constructor = Array
table.freeze(prototype)

--[=[
	@within Array
	@function __call
	@param ... unknown -- either one non-negative integer length, or the elements
	@return Array<T> -- the new array

	`Array(...)` without `new` behaves exactly like `new Array(...)`, as in
	JavaScript. The call is forwarded to `__toArray`, so the same caveats apply.
]=]
setmetatable(Array, {
	__call = function(_, ...): esTypes.Array<unknown>
		return __toArray(...)
	end,
})

table.freeze(Array)
return Array
