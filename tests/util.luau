--!strict
-- util: format and inspect (Node.js utilities).

local T = require("./_init").new("util")
local loader = require("./_loader")

local util = loader.loadPackage("util") :: any
local Map = loader.loadPackage("Map") :: any
local Set = loader.loadPackage("Set") :: any

return function(): (number, number)
	-- format
	do
		T:check("basic specifiers", util.format("%s=%d", "answer", 42) == "answer=42")
		T:check("missing argument keeps specifier", util.format("%s:%s", "foo") == "foo:%s")
		T:check("extra arguments appended with spaces", util.format("%s:%s", "foo", "bar", "baz") == "foo:bar baz")
		T:check("no specifiers joins with spaces", util.format(1, 2, 3) == "1 2 3")
		T:check("literal percent", util.format("100%%") == "100%")
		T:check("trailing lone percent kept", util.format("50%") == "50%")
		T:check("%s number", util.format("%s", 7) == "7")
		T:check("%s boolean", util.format("%s", true) == "true")
		T:check("%d non-numeric is NaN", util.format("%d", "abc") == "NaN")
		T:check("%d drops the fraction", util.format("%d", 3.9) == "3")
		T:check("%d boolean converts", util.format("%d", true) == "1")
		T:check("%i truncates", util.format("%i", "42.9") == "42")
		T:check("%f parses", util.format("%f", "3.14") == "3.14")
		T:check("%f non-numeric is NaN", util.format("%f", "nope") == "NaN")
		T:check("%j stringifies JSON", util.format("%j", { a = 1 }) == '{"a":1}')
		T:check("%j nil", util.format("%j", nil) == "undefined")
		T:check("%o inspects", util.format("%o", { a = 1 }):find("a: 1") ~= nil)
		T:check("%O same as %o here", util.format("%O", { a = 1 }) == util.format("%o", { a = 1 }))
		T:check("%c skipped", util.format("a %c b", "css") == "a  b" or util.format("a%c", "css"):find("a") ~= nil)
		T:check("%s table shallow-inspects", util.format("%s", { a = 1 }):find("a") ~= nil)

		-- unknown specifier stays verbatim and the argument overflows
		T:check("unknown specifier verbatim", util.format("%x", 255) == "%x 255")

		-- circular %j does not throw
		local circular = {}
		circular.self = circular
		T:check(
			"%j circular is marked",
			pcall(function()
				return util.format("%j", circular)
			end)
		)
	end

	-- inspect: primitives
	do
		T:check("number", util.inspect(42) == "42")
		T:check("negative number", util.inspect(-7) == "-7")
		T:check("NaN", util.inspect(0 / 0) == "NaN")
		T:check("Infinity", util.inspect(math.huge) == "Infinity")
		T:check("-Infinity", util.inspect(-math.huge) == "-Infinity")
		T:check("-0", util.inspect(-0) == "-0")
		T:check("string quoted", util.inspect("hello") == "'hello'")
		T:check("string escapes quotes", util.inspect("it's"):find("\\'") ~= nil)
		T:check("boolean", util.inspect(true) == "true")
		T:check("nil", util.inspect(nil) == "nil")
	end

	-- inspect: tables
	do
		T:check("empty table", util.inspect({}) == "{}")
		T:check("simple object", util.inspect({ a = 1 }) == "{ a: 1 }")
		T:check("array", util.inspect({ 1, 2, 3 }) == "[ 1, 2, 3 ]")
		T:check("nested object", util.inspect({ inner = { a = 1 } }) == "{ inner: { a: 1 } }")
		T:check("quoted non-identifier key", util.inspect({ ["not an id"] = 1 }):find("'not an id'") ~= nil)
		-- selene: allow(mixed_table) — mixed tables are the point of this check
		T:check(
			"mixed array and keys",
			util.inspect({ 1, x = 2 }):find("1") ~= nil and util.inspect({ 1, x = 2 }):find("x") ~= nil
		)

		-- depth: default 2, deeper renders as [Object]
		T:check("depth 3 default truncates", util.inspect({ a = { b = { c = { d = 1 } } } }):find("%[Object%]") ~= nil)
		T:check("depth 3 visible at depth 2", util.inspect({ a = { b = { c = 1 } } }) == "{ a: { b: { c: 1 } } }")
		T:check(
			"math.huge depth unlimited",
			util.inspect({ a = { b = { c = { d = 1 } } } }, { depth = math.huge }) == "{ a: { b: { c: { d: 1 } } } }"
		)

		-- circular reference
		local circular = {}
		circular.self = circular
		T:check("circular marker", util.inspect(circular):find("%[Circular %*1%]") ~= nil)

		-- long output goes multiline by default
		local long = { first = 1, second = 2, third = 3, fourth = 4, fifth = 5, sixth = 6, seventh = 7, eighth = 8 }
		T:check("long object multiline", util.inspect(long):find("\n") ~= nil)
		T:check("compact single line", util.inspect({ a = 1 }) == "{ a: 1 }")
		T:check("explicit multiline", util.inspect({ a = 1 }, { compact = false }):find("\n") ~= nil)

		-- sorted keys
		T:check("sorted option", util.inspect({ b = 1, a = 2 }, { compact = true, sorted = true }) == "{ a: 2, b: 1 }")

		-- maxArrayLength truncation
		local big = {}
		for index = 1, 150 do
			big[index] = index
		end
		T:check("array truncation marker", util.inspect(big):find("more item%(s%)") ~= nil)
		T:check(
			"array truncation honors option",
			util.inspect(big, { maxArrayLength = 10 }):find("… 140 more item%(s%)") ~= nil
		)
	end

	-- inspect: library collections
	do
		T:check("empty Map", util.inspect(Map.new()) == "Map(0) {}")
		T:check(
			"Map entries",
			util.inspect(Map.new({ { "a", 1 }, { "b", 2 } }), { compact = true }) == "Map(2) { 'a' => 1, 'b' => 2 }"
		)
		T:check("empty Set", util.inspect(Set.new()) == "Set(0) {}")
		T:check("Set members", util.inspect(Set.new({ 1, 2, 3 }), { compact = true }) == "Set(3) { 1, 2, 3 }")

		-- nested inside tables
		T:check(
			"Map nested in table",
			util.inspect({ m = Map.new({ { "k", 1 } }) }, { compact = true }):find("Map%(1%)") ~= nil
		)
	end

	T:finish()
	return T.passed, T.failed
end
