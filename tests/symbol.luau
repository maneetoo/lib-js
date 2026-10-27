--!strict
-- Symbol: uniqueness, descriptions, registry, prototype methods.

local loader = require("./_loader")
local T = require("./_init").new("Symbol")

local Symbol = loader.loadPackage("Symbol") :: any

return function(): (number, number)
	-- uniqueness and description
	do
		local a = Symbol("tag")
		local b = Symbol("tag")
		T:check("symbols with same description differ", a ~= b)
		T:check("isSymbol recognizes symbols", Symbol.isSymbol(a))
		T:check("isSymbol rejects plain tables", not Symbol.isSymbol({}))
		T:check("isSymbol rejects strings", not Symbol.isSymbol("s"))
		T:check("isSymbol rejects nil", not Symbol.isSymbol(nil))

		T:check("description via prototype", Symbol.prototype.description(a) == "tag")
		T:check("no-description symbol", Symbol.prototype.description(Symbol()) == nil)
	end

	-- tostring
	do
		local s = Symbol("x")
		T:check("toString form", Symbol.prototype.toString(s) == "Symbol(x)")
		T:check("toString without description", Symbol.prototype.toString(Symbol()) == "Symbol()")
		T:check("luau tostring uses __tostring", tostring(s) == "Symbol(x)")
	end

	-- global registry
	do
		local k1 = Symbol["for"]("key")
		local k2 = Symbol["for"]("key")
		T:check("registry returns same symbol", k1 == k2)
		T:check("keyFor retrieves key", Symbol.keyFor(k1) == "key")
		T:check("unregistered symbol keyFor nil", Symbol.keyFor(Symbol("x")) == nil)
		T:check("different keys differ", Symbol["for"]("a") ~= Symbol["for"]("b"))
	end

	-- well-known symbols
	do
		local names = {
			"iterator",
			"asyncIterator",
			"hasInstance",
			"isConcatSpreadable",
			"toPrimitive",
			"toStringTag",
			"unscopables",
			"match",
			"matchAll",
			"replace",
			"search",
			"species",
			"split",
		}
		local allDistinct = true
		local seen: { any } = {}
		for _, name in names do
			local sym = Symbol[name]
			if sym == nil or not Symbol.isSymbol(sym) then
				allDistinct = false
			end
			for _, other in seen do
				if sym == other then
					allDistinct = false
				end
			end
			table.insert(seen, sym)
		end
		T:check("all well-known symbols exist", allDistinct)
		T:check("well-known not in registry", Symbol.keyFor(Symbol.iterator) == nil)
	end

	-- prototype sanity
	do
		T:check("prototype has toString", type(Symbol.prototype.toString) == "function")
		T:check("prototype has valueOf", type(Symbol.prototype.valueOf) == "function")
		local s = Symbol("v")
		T:check("valueOf returns self", Symbol.prototype.valueOf(s) == s)
		T:expectError("toString on non-symbol errors", function()
			Symbol.prototype.toString({})
		end)
	end

	T:finish()
	return T.passed, T.failed
end
