--!strict

--[=[
	@class __hierarchy
	@private

	Builds the whole `Error` hierarchy in one module, in dependency order:
	`Error.prototype`, then `Error`, then the native subclasses. Each file in
	`Error/` re-exports one of these values.

	:::note
	`Error.prototype.toString` must throw a `TypeError` for a non-object
	receiver, and `TypeError` inherits from `Error.prototype`. If the two lived
	in separate modules, each would have to load the other. Here
	`throwTypeError` reaches the `TypeError` constructor through an upvalue that
	is assigned later in this file. No module-level `require` forms a cycle.
	:::
]=]

const Symbol = require("../Symbol")
const classes = require("./__class")
const esTypes = require("../ES17-Types")
const toString = require("./prototype/toString")

type ErrorInstance = classes.ErrorInstance
type ErrorConstructor = classes.ErrorConstructor

-- Assigned below, once `TypeError` exists. Reading it at call time is safe.
local TypeErrorConstructor: ErrorConstructor

const function throwTypeError(message: string): never
	error(TypeErrorConstructor.new(message))
end
classes.markInternal(throwTypeError)

const prototype: classes.ErrorPrototype = {
	name = "Error",
	message = "",
	toString = toString(throwTypeError),
}

-- `ErrorPrototype` has no slot for a symbol key, so the tag is written through a
-- table view. Subclass prototypes inherit it through `__index`.
const taggable: esTypes.Table<unknown, unknown> = prototype :: esTypes.Table<unknown, unknown>
taggable[Symbol.toStringTag] = "Error"

--[=[
	Shared argument handling for every constructor. A Symbol cannot be
	converted to a string (JavaScript throws for this too), so it is rejected
	here, where `TypeError` is reachable.
]=]
const function buildError(class: classes.ErrorClass, message: unknown?, options: unknown?): ErrorInstance
	if Symbol.isSymbol(message) then
		error(TypeErrorConstructor.new("Cannot convert a Symbol value to a string"))
	end
	return classes.allocate(class, message, options)
end
classes.markInternal(buildError)

const errorClass = classes.createBaseClass("Error", prototype)
const ErrorConstructor = classes.makeConstructor(
	errorClass,
	function(message: unknown?, options: unknown?): ErrorInstance
		return buildError(errorClass, message, options)
	end,
	nil
)

const function defineSubclass(name: string): ErrorConstructor
	const subclass = classes.createSubclass(name, prototype)
	return classes.makeConstructor(subclass, function(message: unknown?, options: unknown?): ErrorInstance
		return buildError(subclass, message, options)
	end, ErrorConstructor)
end

TypeErrorConstructor = defineSubclass("TypeError")

const EvalErrorConstructor = defineSubclass("EvalError")
const RangeErrorConstructor = defineSubclass("RangeError")
const ReferenceErrorConstructor = defineSubclass("ReferenceError")
const SyntaxErrorConstructor = defineSubclass("SyntaxError")
const URIErrorConstructor = defineSubclass("URIError")

const aggregateClass = classes.createSubclass("AggregateError", prototype)
const AggregateErrorConstructor = classes.makeConstructor(
	aggregateClass,
	function(errors: unknown, message: unknown?, options: unknown?): ErrorInstance
		local list: esTypes.Array<unknown>
		if type(errors) == "string" then
			-- Strings are iterable in JavaScript, so their code points become
			-- the error list instead of being rejected.
			list = {}
			local count = 0
			for _, codePoint in utf8.codes(errors :: string) do
				count += 1
				list[count] = utf8.char(codePoint)
			end
		elseif type(errors) == "table" and not Symbol.isSymbol(errors) then
			list = errors :: esTypes.Array<unknown>
		else
			error(TypeErrorConstructor.new("AggregateError: errors is not iterable"))
		end

		const instance = buildError(aggregateClass, message, options)
		const copy: esTypes.Array<unknown> = {}
		for index = 1, #list do
			copy[index] = list[index]
		end
		instance.errors = copy
		return instance
	end,
	ErrorConstructor
)

-- Each subclass is also a static field of `Error`, so `Error.TypeError` gives
-- the same constructor as `require "Error/TypeError"`. Luau does not type the
-- added fields on `Error`, so `init.luau` gives the type.
const statics = {
	AggregateError = AggregateErrorConstructor,
	EvalError = EvalErrorConstructor,
	RangeError = RangeErrorConstructor,
	ReferenceError = ReferenceErrorConstructor,
	SyntaxError = SyntaxErrorConstructor,
	TypeError = TypeErrorConstructor,
	URIError = URIErrorConstructor,
}
for name, constructor in statics do
	(ErrorConstructor :: any)[name] = constructor
end

-- The constructors were left unfrozen by `makeConstructor`, so freeze them now.
for _, constructor in
	{
		ErrorConstructor,
		AggregateErrorConstructor,
		EvalErrorConstructor,
		RangeErrorConstructor,
		ReferenceErrorConstructor,
		SyntaxErrorConstructor,
		TypeErrorConstructor,
		URIErrorConstructor,
	}
do
	table.freeze(constructor)
end

return table.freeze({
	prototype = prototype,
	Error = ErrorConstructor,
	EvalError = EvalErrorConstructor,
	RangeError = RangeErrorConstructor,
	ReferenceError = ReferenceErrorConstructor,
	SyntaxError = SyntaxErrorConstructor,
	TypeError = TypeErrorConstructor,
	URIError = URIErrorConstructor,
	AggregateError = AggregateErrorConstructor,
})
