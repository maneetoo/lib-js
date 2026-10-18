--!strict

--[=[
	@class Array.prototype

	The methods of `Array.prototype`. Every method takes the array as its first
	argument, so call `Array.prototype.map(arr, fn)`. Arrays are plain tables, so no
	`arr:map(fn)` form is available.

	Frozen once the module is loaded.
]=]

const Symbol = require "../Symbol"
const values = require "@self/values"

--[=[
	@within Array.prototype
	@private

	`Array.prototype[Symbol.unscopables]`. Names that a `with` statement should not
	resolve against the array. Only the names listed here are `true`.
]=]
const unscopables = {
	at = true,
	copyWithin = true,
	entries = true,
	fill = true,
	find = true,
	findIndex = true,
	findLast = true,
	findLastIndex = true,
	flat = true,
	flatMap = true,
	includes = true,
	keys = true,
	toReversed = true,
	toSorted = true,
	toSpliced = true,
	values = true,
}
table.freeze(unscopables)

--[=[
	@within Array
	@type Prototype = { at: ..., concat: ..., ..., [Symbol.iterator]: ..., [Symbol.unscopables]: ... }

	Every method of `Array.prototype`. `[Symbol.iterator]` is `values`.
]=]

const prototype = {
    at = require "@self/at",
    concat = require "@self/concat",
    copyWithin = require "@self/copyWithin",
    entries = require "@self/entries",
    every = require "@self/every",
    fill = require "@self/fill",
    filter = require "@self/filter",
    find = require "@self/find",
    findIndex = require "@self/findIndex",
    findLast = require "@self/findLast",
    findLastIndex = require "@self/findLastIndex",
    flat = require "@self/flat",
    flatMap = require "@self/flatMap",
    forEach = require "@self/forEach",
    includes = require "@self/includes",
    indexOf = require "@self/indexOf",
    join = require "@self/join",
    keys = require "@self/keys",
    lastIndexOf = require "@self/lastIndexOf",
    map = require "@self/map",
    pop = require "@self/pop",
    push = require "@self/push",
    reduce = require "@self/reduce",
    reduceRight = require "@self/reduceRight",
    reverse = require "@self/reverse",
    shift = require "@self/shift",
    slice = require "@self/slice",
    some = require "@self/some",
    sort = require "@self/sort",
    splice = require "@self/splice",
    toReversed = require "@self/toReversed",
    toSorted = require "@self/toSorted",
    toSpliced = require "@self/toSpliced",
    toString = require "@self/toString",
    unshift = require "@self/unshift",
    values = values,
    with = require "@self/with",
}

prototype[Symbol.iterator] = values
prototype[Symbol.unscopables] = unscopables

return prototype
