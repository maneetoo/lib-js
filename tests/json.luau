--!strict
-- JSON: parse, stringify, rawJSON.

local loader = require("./_loader")
local T = require("./_init").new("JSON")

local JSON = loader.loadPackage("JSON") :: any

return function(): (number, number)
	-- parse: primitives and containers
	do
		T:check("parse number", JSON.parse("42") == 42)
		T:check("parse negative number", JSON.parse("-3.5") == -3.5)
		T:check("parse string", JSON.parse('"hi"') == "hi")
		T:check("parse true", JSON.parse("true") == true)
		T:check("parse false", JSON.parse("false") == false)
		T:check("parse null", JSON.parse("null") == nil)
		T:check("parse array", JSON.parse("[1,2,3]")[2] == 2)
		local obj = JSON.parse('{"a":1,"b":"x"}')
		T:check("parse object", obj.a == 1 and obj.b == "x")
		local nested = JSON.parse('{"a":[1,{"b":true}]}')
		T:check("parse nested", nested.a[2].b == true)
		T:check("parse empty object", JSON.parse("{}") ~= nil)
		T:check("parse empty array", #JSON.parse("[]") == 0)

		T:expectError("parse invalid syntax", function()
			JSON.parse("{a:1}")
		end)
		T:expectError("parse trailing garbage", function()
			JSON.parse("1 2")
		end)
		T:expectError("parse empty string", function()
			JSON.parse("")
		end)
		T:expectError("parse single quotes", function()
			JSON.parse("'x'")
		end)
	end

	-- stringify: primitives, containers, quoting
	do
		T:check("stringify number", JSON.stringify(42) == "42")
		T:check("stringify string", JSON.stringify("hi") == '"hi"')
		T:check("stringify true", JSON.stringify(true) == "true")
		T:check("stringify nil is undefined (omitted)", JSON.stringify(nil) == nil)
		T:check("stringify array", JSON.stringify({ 1, 2, 3 }) == "[1,2,3]")
		T:check("stringify object", JSON.stringify({ a = 1 }) == '{"a":1}')
		T:check("stringify nested", JSON.stringify({ { 1 } }) == "[[1]]")
		T:check("stringify escapes quotes", JSON.stringify('say "hi"') == '"say \\"hi\\""')
		T:check("stringify empty array", JSON.stringify({}) == "[]")
		T:check("stringify nil in array is null", JSON.stringify({ 1, nil, 3 }) == "[1,null,3]")
	end

	-- stringify: replacer and spacing
	do
		T:check("stringify indent", JSON.stringify({ 1 }, nil, 2):find("\n") ~= nil)
		T:check("stringify indent number", JSON.stringify({ 1 }, nil, 4):find("    1") ~= nil)
		local filtered = JSON.stringify({ a = 1, b = 2 }, { "a" })
		T:check("replacer array filters", filtered == '{"a":1}')
		local mapped = JSON.stringify({ a = 1 }, function(_key, value)
			return value
		end)
		T:check("replacer function passes through", mapped == '{"a":1}')
	end

	-- rawJSON: valid JSON primitives only, kept verbatim
	do
		local raw = JSON.rawJSON("1.0")
		T:check("isRawJSON recognizes", JSON.isRawJSON(raw))
		T:check("isRawJSON rejects plain", not JSON.isRawJSON({}))
		T:check("rawJSON stringifies verbatim", JSON.stringify(raw) == "1.0")
		T:check("rawJSON null kept", JSON.stringify(JSON.rawJSON("null")) == "null")
		T:expectError("rawJSON rejects objects", function()
			JSON.rawJSON('{"a":1}')
		end)
		T:expectError("rawJSON rejects invalid text", function()
			JSON.rawJSON("not json")
		end)
		T:expectError("rawJSON rejects whitespace", function()
			JSON.rawJSON(" 1 ")
		end)
	end

	-- round-trip
	do
		local text = '{"name":"lib-js","n":7,"list":[1,2,3]}'
		local parsed = JSON.parse(text)
		T:check("round-trip value", parsed.name == "lib-js" and parsed.n == 7)
		T:check("round-trip array", #parsed.list == 3)
		local out = JSON.stringify(parsed)
		-- Key order follows Luau iteration, so compare by re-parsing
		local reparsed = JSON.parse(out)
		T:check("round-trip is lossless", reparsed.name == "lib-js" and reparsed.n == 7 and #reparsed.list == 3)
	end

	T:finish()
	return T.passed, T.failed
end
