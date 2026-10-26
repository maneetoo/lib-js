--!strict

--[=[
	@class String

	A Luau port of JavaScript's [`String`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String):
	the static helpers (`fromCharCode`, `fromCodePoint`, `raw`), a
	`String.prototype` sub-table holding the instance methods (`at`,
	`indexOf`, `slice`, `split`, ...), and a constructor: calling
	`String(value)` itself.

	:::note
	Indices, lengths and positions are counted in **Unicode code points**,
	not in UTF-8 bytes (Luau's native unit) and not in UTF-16 code units
	(JavaScript's unit). A character outside the Basic Multilingual Plane,
	such as an emoji, is one unit here, but two units in JavaScript.
	All indices are 0-based, as in JavaScript.
	:::

	:::note
	`String(value)` returns a plain, primitive Luau `string`, matching the
	bare call in JavaScript. Primitives are never boxed, so string methods
	are called directly: `String.prototype.trim(s)`.
	:::

	:::caution
	`length` is a property in JavaScript, but a Luau string cannot carry
	properties. Use `String.prototype.length(s)` instead.
	:::

	:::caution
	Regular expressions are not supported. Methods that take a pattern
	(`replace`, `replaceAll`, `split`, `includes`, ...) accept only strings.
	`match`, `matchAll` and `search` are not implemented.
	:::

	:::note
	Locale-aware methods (`localeCompare`, `normalize`,
	`toLocaleLowerCase`, `toLocaleUpperCase`) are intentionally not
	implemented, for the same reason as `Number.prototype.toLocaleString`.
	:::

	:::note
	Both `String` and `String.prototype` are frozen with `table.freeze`
	before being returned, so the public surface is immutable.
	:::
]=]

const ECMAScript = require("./ECMAScript")
const Symbol = require("./Symbol")
const prototype = require("@self/prototype")

const String = {
	fromCharCode = require("@self/fromCharCode"),
	fromCodePoint = require("@self/fromCodePoint"),
	raw = require("@self/raw"),

	__toString = ECMAScript.ToString,
	prototype = prototype,
}

--[=[
	@within String
	@function __call
	@param value unknown -- the value to convert
	@return string -- `value` converted with `ToString`

	`String()` with no argument returns `""`. `String(undefined)` returns
	`"undefined"`, as in JavaScript. A symbol converts to its descriptive
	string (`"Symbol(description)"`), not to an error, because `String` is
	the explicit conversion.
]=]
setmetatable(String, {
	__call = function(_, ...): string
		if select("#", ...) == 0 then
			return ""
		end
		const value = ...
		if Symbol.isSymbol(value) then
			return Symbol.prototype.toString(value :: any)
		end
		return ECMAScript.ToString(value)
	end,
})

table.freeze(String)
return String
