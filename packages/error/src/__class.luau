--!strict

--[=[
	@class __class
	@private

	Shared machinery for the `Error` hierarchy: class construction, instance
	allocation, the `stack` capture, and the `ToString` conversion applied to
	messages.

	A class is a prototype table plus a per-class instance metatable whose
	`__index` is that prototype, so `instanceof` works through the usual
	metatable chain.

	:::note
	The instance metatable is created once per class and reused by every
	instance, so creating an error allocates only the instance table and its
	`stack` string.
	:::
]=]

const Number = require "../Number"
const Object = require "../Object"
const esTypes = require "../ES17-Types"

export type ErrorInstance = {
	message: string,
	stack: string,
	cause: unknown?,
	errors: esTypes.Array<unknown>?,
}

export type ErrorPrototype = {
	name: string,
	message: string,
	toString: (unknown) -> string,
	constructor: ErrorConstructor?,
}

export type ErrorMetatable = {
	read __index: ErrorPrototype,
	read __tostring: (ErrorInstance) -> string,
}

export type ErrorClass = {
	name: string,
	prototype: ErrorPrototype,
	metatable: ErrorMetatable,
}

export type ErrorConstructor = {
	read name: string,
	read prototype: ErrorPrototype,
	read new: (...unknown) -> ErrorInstance,
}

--[=[
	The native subclasses, as static fields of `Error`: `Error.TypeError` and so on.
]=]
export type ErrorStatics = {
	read AggregateError: ErrorConstructor,
	read EvalError: ErrorConstructor,
	read RangeError: ErrorConstructor,
	read ReferenceError: ErrorConstructor,
	read SyntaxError: ErrorConstructor,
	read TypeError: ErrorConstructor,
	read URIError: ErrorConstructor,
}

-- Every class metatable, so `isError` recognises instances in O(1).
const classMetatables: esTypes.Table<unknown, boolean> = setmetatable({} :: esTypes.Table<unknown, boolean>, { __mode = "k" })

--[=[
	Functions that belong to the library's own call path. The `stack` capture
	skips them by identity, so the first frame it keeps is user code. Frame
	indices are not used: `return f(...)` is a tail call in Luau, so a fixed
	index can point past user code or inside the library, depending on how
	the error was built.
]=]
const internalFunctions: esTypes.Table<unknown, boolean> = setmetatable({} :: esTypes.Table<unknown, boolean>, { __mode = "k" })

--[=[
	@within __class
	@param fn unknown -- a function that belongs to the library's call path
]=]
const function markInternal(fn: unknown)
	internalFunctions[fn] = true
end

const STACK_LIMIT = 10 -- V8's default `Error.stackTraceLimit`
const NATIVE_SOURCE = "[C]"

--[=[
	@within __class
	@param value unknown -- the value to convert
	@return string -- the value as JavaScript's `ToString` would produce it

	Numbers use `Number.prototype.toString`, so `Infinity` and `1e+21` match JavaScript.
	Tables use their `toString` method when they have a callable one. Otherwise
	the result is `Object.prototype.toString`, which gives `"[object Object]"` for
	a plain object, as JavaScript does.

	:::caution
	JavaScript throws for a Symbol here. The `Error` constructors reject
	symbols before they reach this function, so a symbol never gets this far.
	:::
]=]
const function toJsString(value: unknown): string
	if value == nil then
		return "undefined"
	end
	if type(value) == "string" then
		return value
	end
	if type(value) == "number" then
		return Number.prototype.toString(value)
	end
	if type(value) == "boolean" then
		return if value then "true" else "false"
	end
	if type(value) == "function" then
		return "function () { [native code] }"
	end
	if type(value) == "table" then
		const object = value :: esTypes.Table<unknown, unknown>
		const toStringFn = object["toString"]
		if type(toStringFn) == "function" then
			const result = (toStringFn :: (unknown) -> unknown)(value)
			if type(result) == "string" then
				return result
			end
		end
	end
	return Object.prototype.toString(value)
end

--[=[
	@within __class
	@param name string -- the class name, e.g. `"TypeError"`
	@param prototype ErrorPrototype -- the prototype of a root class, which has no parent
	@return ErrorClass -- the new class

	Used for `Error` itself, whose prototype is built by `Error/__hierarchy.luau`.
]=]
const function createBaseClass(name: string, prototype: ErrorPrototype): ErrorClass
	const metatable: ErrorMetatable = table.freeze {
		__index = prototype,
		__tostring = function(self: ErrorInstance): string
			return prototype.toString(self)
		end,
	}
	classMetatables[metatable] = true

	return {
		name = name,
		prototype = prototype,
		metatable = metatable,
	}
end

--[=[
	@within __class
	@param name string -- the class name, e.g. `"TypeError"`
	@param parent ErrorPrototype -- the prototype of the superclass
	@return ErrorClass -- the new class

	A subclass prototype owns `name`. It also holds copies of `message` and
	`toString` from the parent. The parent is frozen, so the copies always
	match what JavaScript inheritance would give. Its metatable `__index` keeps
	the prototype chain for every other property.
]=]
const function createSubclass(name: string, parent: ErrorPrototype): ErrorClass
	const prototype: ErrorPrototype = {
		name = name,
		message = parent.message,
		toString = parent.toString,
	}
	setmetatable(prototype, { __index = parent })

	const metatable: ErrorMetatable = table.freeze {
		__index = prototype,
		__tostring = function(self: ErrorInstance): string
			return prototype.toString(self)
		end,
	}
	classMetatables[metatable] = true

	return {
		name = name,
		prototype = prototype,
		metatable = metatable,
	}
end

--[=[
	@within __class
	@param header string -- the first line of the stack, e.g. `"TypeError: bad"`
	@return string -- `header` followed by one `    at` line per user frame

	Walks the call stack from the top. Internal frames are skipped by
	identity, so the first kept frame is the code that called into this
	library. Each frame prints as `    at <name> (<source>:<line>)`, the
	format V8 uses, with at most `STACK_LIMIT` frames.

	:::caution
	Columns are not reported, because `debug.info` does not provide them.
	:::
]=]
const function captureStack(header: string): string
	-- Level 1 is this function. Skip it and every internal frame above it.
	local level = 1
	while true do
		const fn = debug.info(level, "f")
		if fn == nil or not internalFunctions[fn] then
			break
		end
		level += 1
	end

	const lines: { string } = {}
	while #lines < STACK_LIMIT do
		const source, line, name = debug.info(level, "sln")
		if source == nil then
			break
		end

		local where: string
		if source == NATIVE_SOURCE then
			where = "native"
		else
			where = (string.gsub(source, "^[@=]", "")) .. ":" .. tostring(line)
		end
		lines[#lines + 1] = "    at " .. (name or "<anonymous>") .. " (" .. where .. ")"
		level += 1
	end

	if #lines == 0 then
		return header
	end
	return header .. "\n" .. table.concat(lines, "\n")
end
markInternal(captureStack)

--[=[
	@within __class
	@param class ErrorClass -- the class to instantiate
	@param message unknown? -- converted with `ToString`; `nil` leaves `message` empty
	@param options unknown? -- when a table with a `cause` field, that field is copied onto the error; any other value is ignored
	@return ErrorInstance -- the new error instance

	:::caution
	`cause` is copied only when it is not `nil`. Luau cannot distinguish
	`undefined` from an absent field, so `{ cause = nil }` behaves as `{}`.
	:::
]=]
const function allocate(class: ErrorClass, message: unknown?, options: unknown?): ErrorInstance
	const instance: ErrorInstance = {
		message = if message == nil then "" else toJsString(message),
		stack = "",
	}
	setmetatable(instance, class.metatable)

	if type(options) == "table" then
		const cause = (options :: esTypes.Table<string, unknown>)["cause"]
		if cause ~= nil then
			instance.cause = cause
		end
	end

	instance.stack = captureStack(class.prototype.toString(instance))
	return instance
end
markInternal(allocate)

--[=[
	@within __class
	@param class ErrorClass -- the class the constructor creates instances of
	@param new (...unknown) -> ErrorInstance -- the builder that calls `allocate`
	@param parent ErrorConstructor? -- the parent constructor, for static inheritance (`TypeError.__proto__ === Error`)
	@return ErrorConstructor -- a frozen constructor, callable and exposing `new`

	Sets `constructor` on the prototype and freezes the prototype. Returns the
	constructor, which the caller freezes after any static fields are added. Returns a constructor
	callable both as `Class(...)` and as `Class.new(...)`, as in JavaScript,
	where error constructors work with or without `new`.

	:::caution
	The call form `Class(...)` works at runtime, but Luau types cannot express
	a callable table. Type-checked code should use `Class.new(...)`.
	:::
]=]
const function makeConstructor(class: ErrorClass, new: (...unknown) -> ErrorInstance, parent: ErrorConstructor?): ErrorConstructor
	const constructor: ErrorConstructor = {
		name = class.name,
		prototype = class.prototype,
		new = new,
	}
	class.prototype.constructor = constructor

	const callWrapper = function(_: unknown, ...: unknown): ErrorInstance
		return new(...)
	end
	markInternal(new)
	markInternal(callWrapper)

	setmetatable(constructor, {
		__index = parent,
		__call = callWrapper,
	})

	table.freeze(class.prototype)
	-- Not frozen yet: `__hierarchy` adds the subclasses to `Error` and then freezes it.
	return constructor
end

--[=[
	@within __class
	@param value unknown -- the value to test
	@return boolean -- `true` if `value` was created by one of this library's error classes

	Checks the instance's own metatable, so objects that merely inherit from
	an error prototype are not reported.
]=]
const function isError(value: unknown): boolean
	if type(value) ~= "table" then
		return false
	end
	const metatable = getmetatable(value)
	return metatable ~= nil and classMetatables[metatable] == true
end

return table.freeze {
	createBaseClass = createBaseClass,
	createSubclass = createSubclass,
	allocate = allocate,
	makeConstructor = makeConstructor,
	isError = isError,
	toJsString = toJsString,
	markInternal = markInternal,
}
