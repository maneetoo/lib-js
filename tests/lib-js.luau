--!strict
-- lib-js: the aggregate module re-exports every package coherently.

local T = require("./_init").new("lib-js")
local loader = require("./_loader")

local lib = loader.loadPackage("LibJS") :: any

return function(): (number, number)
	-- every namespace is present and is the same module as direct loads
	do
		local namespaces = {
			{ "Array", "Array" },
			{ "Boolean", "Boolean" },
			{ "Error", "Error" },
			{ "JSON", "JSON" },
			{ "Map", "Map" },
			{ "Math", "Math" },
			{ "Number", "Number" },
			{ "Object", "Object" },
			{ "Promise", "Promise" },
			{ "Set", "Set" },
			{ "String", "String" },
			{ "Symbol", "Symbol" },
			{ "Timers", "Timers" },
			{ "WeakMap", "WeakMap" },
			{ "WeakRef", "WeakRef" },
			{ "WeakSet", "WeakSet" },
			{ "globalThis", "globalThis" },
			{ "instanceof", "instanceof" },
			{ "iterate", "iterate" },
		}
		for _, entry in namespaces do
			local field, package = entry[1], entry[2]
			local direct = loader.loadPackage(package)
			T:check(`{field} re-exports the real package`, lib[field] == direct)
		end
	end

	-- global-function shims point at the Number implementations
	do
		local Number = lib.Number
		T:check("isNaN shim", lib.isNaN == Number.isNaN)
		T:check("isFinite shim", lib.isFinite == Number.isFinite)
		T:check("parseInt shim", lib.parseInt == Number.parseInt)
		T:check("parseFloat shim", lib.parseFloat == Number.parseFloat)
	end

	-- the aggregate is frozen
	do
		T:expectError("lib-js is frozen", function()
			(lib :: any).extra = 1
		end)
	end

	-- sanity: a representative method from each namespace works
	do
		T:check("Array.isArray", lib.Array.isArray({}))
		T:check("Math.abs", lib.Math.abs(-1) == 1)
		T:check("JSON round trip", lib.JSON.parse('{"a":1}').a == 1)
		T:check("Promise.resolve exists", type(lib.Promise.resolve) == "function")
		T:check("Symbol.isSymbol", lib.Symbol.isSymbol(lib.Symbol.iterator))
		T:check("Map.new", lib.Map.new().size == 0)
		T:check("Object.keys", #lib.Object.keys({ a = 1 }) == 1)
	end

	T:finish()
	return T.passed, T.failed
end
