--!strict

--[=[
	@class Error

	A Luau port of JavaScript's
	[`Error`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error):
	the base class of the error hierarchy.

	The native subclasses are separate modules, as their JavaScript
	counterparts are separate globals:

	- `Error/EvalError`
	- `Error/RangeError`
	- `Error/ReferenceError`
	- `Error/SyntaxError`
	- `Error/TypeError`
	- `Error/URIError`
	- `Error/AggregateError`

	Every class supports both `Error(message?, options?)` and
	`Error.new(message?, options?)`. Subclass constructors inherit statics from
	`Error` (`Object.getPrototypeOf(TypeError) === Error`).

	:::note
	`stack` has the JavaScript shape, `Name: message` followed by
	`    at name (source:line)` lines, with at most 10 frames. It is captured on
	every construction, so it costs a stack walk each time.
	:::

	:::note
	`message` is converted with JavaScript's `ToString`. A table passed as the
	message becomes `[object Object]`, or the result of its `toString` method.
	:::

	:::caution
	Not reproducible in Luau, and therefore not implemented:

	- `typeof err` is `"table"`, because Luau has no other type for it.
	- `message`, `stack`, `cause`, and `errors` are own *enumerable* keys.
	  JavaScript makes them non-enumerable. Moving them behind `__index` would
	  remove them from `Object.keys`, but would also break `hasOwnProperty`
	  and `in`, which are the more common checks.
	- `cause: undefined` cannot be told apart from an absent `cause`.
	- `message` is always an own field, set to `""` when no message is given.
	  JavaScript inherits it from `Error.prototype` in that case. The value is the same.
	- `Error.prototype.toString` throws for a userdata receiver. JavaScript accepts any object.
	- `class MyError extends Error` has no equivalent. The class machinery is
	  internal, so user subclasses are not supported.
	- Native stack columns, and `Error.captureStackTrace` / `Error.stackTraceLimit`.
	  The first is not reported by `debug.info`. The other two are V8 extensions, not standard JavaScript.
	- The prototypes and constructors are frozen, so user code cannot patch
	  `TypeError.prototype.name`. JavaScript allows it.
	:::

	:::caution
	`EvalError` is never thrown by this library, because Luau has no `eval`.
	:::
]=]

const __class = require "@self/__class"
const __hierarchy = require "@self/__hierarchy"

-- `hierarchy.Error` has the subclasses as static fields at runtime. The cast gives
-- them their types, which Luau cannot infer from `__hierarchy`.
return __hierarchy.Error :: __class.ErrorConstructor & __class.ErrorStatics
