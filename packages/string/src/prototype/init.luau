--!strict

--[=[
	@class StringPrototype

	A Luau port of JavaScript's `String.prototype` instance methods.

	:::caution
	Luau strings cannot carry a metatable that a user can set, so these
	methods are always called directly with the string as their first
	argument: `String.prototype.trim("  x  ")`. The `s:trim()` form is not
	available.
	:::

	:::note
	Keys that are Luau keywords are written with brackets, as with
	`Symbol["for"]`. The method `repeat` is therefore `prototype["repeat"]`.
	:::

	:::note
	`trimLeft` and `trimRight` are the same functions as `trimStart` and
	`trimEnd`, as in JavaScript.
	:::
]=]

const Symbol = require("../Symbol")

const prototype = {
	at = require("@self/at"),
	charAt = require("@self/charAt"),
	charCodeAt = require("@self/charCodeAt"),
	codePointAt = require("@self/codePointAt"),
	concat = require("@self/concat"),
	endsWith = require("@self/endsWith"),
	includes = require("@self/includes"),
	indexOf = require("@self/indexOf"),
	isWellFormed = require("@self/isWellFormed"),
	lastIndexOf = require("@self/lastIndexOf"),
	length = require("@self/length"),
	padEnd = require("@self/padEnd"),
	padStart = require("@self/padStart"),
	["repeat"] = require("@self/repeat"),
	replace = require("@self/replace"),
	replaceAll = require("@self/replaceAll"),
	slice = require("@self/slice"),
	split = require("@self/split"),
	startsWith = require("@self/startsWith"),
	substr = require("@self/substr"),
	substring = require("@self/substring"),
	toLowerCase = require("@self/toLowerCase"),
	toString = require("@self/toString"),
	toUpperCase = require("@self/toUpperCase"),
	toWellFormed = require("@self/toWellFormed"),
	trim = require("@self/trim"),
	trimEnd = require("@self/trimEnd"),
	trimStart = require("@self/trimStart"),
	valueOf = require("@self/valueOf"),
}

prototype.trimLeft = prototype.trimStart
prototype.trimRight = prototype.trimEnd
prototype[Symbol.iterator] = require("@self/iterator")

table.freeze(prototype)
return prototype
