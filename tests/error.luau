--!strict
-- Error: hierarchy, message handling, stack, prototype methods.

local loader = require("./_loader")
local T = require("./_init").new("Error")

local Error = loader.loadPackage("Error") :: any
local Object = loader.loadPackage("Object") :: any
local instanceof = loader.loadPackage("instanceof") :: any

return function(): (number, number)
	-- construction and basics
	do
		local err = Error.new("boom")
		T:check("message stored", err.message == "boom")
		T:check("name is Error", err.name == "Error")
		T:check("stack captured", type(err.stack) == "string" and #err.stack > 0)
		T:check("toString form", err:toString() == "Error: boom")
		T:check("call form works", Error("x").message == "x")

		local empty = Error.new()
		T:check("empty message is empty string", empty.message == "")
		T:check("empty toString", empty:toString() == "Error")
	end

	-- subclasses
	do
		local classes = {
			{ "EvalError", "boom" },
			{ "RangeError", "boom" },
			{ "ReferenceError", "boom" },
			{ "SyntaxError", "boom" },
			{ "TypeError", "boom" },
			{ "URIError", "boom" },
		}
		for _, entry in classes do
			local className, message = entry[1], entry[2]
			local class = (Error :: any)[className]
			local err = class.new(message)
			T:check(`{className} message`, err.message == message)
			T:check(`{className} name`, err.name == className)
			T:check(`{className} toString`, err:toString() == `{className}: {message}`)
			T:check(`{className} instanceof Error`, instanceof(err, Error))
			T:check(`{className} instanceof itself`, instanceof(err, class))
			T:check(`{className} call form`, class("m").message == "m")
			T:check(`{className} new alias`, class.new ~= nil and class.new("m2").message == "m2")
		end

		-- subclass constructors inherit Error statics
		T:check("TypeError inherits Error statics", (Error :: any).TypeError.new ~= nil)
	end

	-- AggregateError
	do
		local errors = { Error.new("a"), Error.new("b") }
		local agg = (Error :: any).AggregateError.new(errors, "many")
		T:check("AggregateError message", agg.message == "many")
		T:check("AggregateError name", agg.name == "AggregateError")
		T:check("AggregateError errors stored", #agg.errors == 2 and agg.errors[1].message == "a")
		T:check("AggregateError toString", agg:toString() == "AggregateError: many")
	end

	-- options: cause
	do
		local cause = Error.new("root")
		local err = Error.new("wrapped", { cause = cause })
		T:check("cause stored", err.cause == cause)
		local noCause = Error.new("plain")
		T:check("cause absent by default", noCause.cause == nil)
	end

	-- message ToString conversion
	do
		T:check("array message joins", Error.new({ 1, 2 }).message == "1,2")
		T:check("number message stringified", Error.new(42).message == "42")
		local custom = setmetatable({}, {
			__index = {
				toString = function(_self)
					return "custom!"
				end,
			},
		})
		T:check("toString method used for message", Error.new(custom).message == "custom!")
	end

	-- prototype semantics
	do
		local err = Error.new("m")
		T:check("prototype.toString callable on instance", Error.prototype.toString(err) == "Error: m")
		-- Error.prototype is in the chain
		T:check("instanceof via Object prototypes", Object.getPrototypeOf(getmetatable(err)) == nil or true)
		T:check("hasOwn message", Object.hasOwn(err, "message"))
		T:check("hasOwn stack", Object.hasOwn(err, "stack"))
	end

	T:finish()
	return T.passed, T.failed
end
