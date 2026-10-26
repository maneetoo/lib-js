--!strict

--[=[
	@class Boolean

	A Luau port of JavaScript's [`Boolean`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean):
	a constructor function coercing its argument to a primitive
	`boolean`, plus a `Boolean.prototype` holding `toString`/`valueOf`.

	:::note
	Unlike this library's `Number` (and unlike real JS's `new
	Number(x)`), calling `Boolean(x)` here always returns a plain,
	unboxed Luau `boolean` — there is no separate "boxed instance" mode
	at all, not even one reachable only via some hypothetical `new`.
	This is a deliberate design choice, not a missing feature: a boxed
	boolean object would carry only `toString`/`valueOf` and otherwise
	behave like a landmine in real JS too, in particular because
	`new Boolean(false)` is itself *truthy* (`if (new Boolean(false))`
	runs its body!) — a notorious gotcha specifically because an object
	wrapper is never falsy, no matter what primitive it wraps. Boxing it
	here would buy nothing except reproducing that trap, so
	`Boolean(x)` instead always matches real JS's bare (non-`new`) call
	form: coerce `x` via `ToBoolean` and hand back the primitive result
	directly.
	:::

	:::caution
	Coercion follows JS's `ToBoolean` exactly, which is narrower than it
	might look at first glance: only `nil` (JS's `undefined`/`null`),
	`false`, the numbers `0`/`-0`, `NaN`, and `""` are falsy. Everything
	else — including an empty table `{}`, which might look "empty" and
	therefore tempting to treat as falsy — is truthy, exactly as
	`Boolean({})` is `true` in JS. See the internal `_toBoolean` module
	for the exact rules.
	:::

	:::note
	Both `Boolean` and `Boolean.prototype` are frozen with
	`table.freeze` before being returned, making the whole public
	surface immutable — no new static members can be added, and none of
	the existing ones (including `prototype` itself) can be reassigned.
	`table.freeze` never replaces a table with a different object and
	never touches an already-installed metatable, so this `Boolean(x)`
	constructor (wired up via `__call` below) keeps working normally
	after freezing.
	:::
]=]

const ECMAScript = require("./ECMAScript")
const prototype = require("@self/prototype")

const Boolean = {
	__toBoolean = ECMAScript.ToBoolean,
	prototype = prototype,
}

--[=[
	@within Boolean
	@function __call
	@param value any? -- the value to coerce
	@return boolean -- `value` coerced to a primitive boolean via `ToBoolean`

	`Boolean(value)` and `Boolean()` are equivalent in effect: with no
	argument at all, `value` is `nil`, which coerces to `false` — the
	same outcome bare `Boolean()` produces in JS (`undefined` is falsy).
]=]
setmetatable(Boolean, {
	__call = function(_, value: any): boolean
		return ECMAScript.ToBoolean(value)
	end,
})

table.freeze(Boolean)
return Boolean
