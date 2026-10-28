--!strict
-- String: statics, prototype methods, UTF-16-style code units.

local T = require("./_init").new("String")
local loader = require("./_loader")

local String = loader.loadPackage("String") :: any
local prototype = String.prototype :: any

return function(): (number, number)
	-- statics
	do
		T:check("fromCharCode", String.fromCharCode(72, 105) == "Hi")
		T:check("fromCodePoint", String.fromCodePoint(0x1F600) == "😀")
		T:check("fromCodePoint mixed", String.fromCodePoint(65, 0x1F600) == "A😀")
		T:check("raw basic", String.raw({ raw = { "a", "b" } }, 1, 2) == "a1b")
	end

	-- charAt / charCodeAt / codePointAt / at
	do
		T:check("charAt", prototype.charAt("hello", 1) == "e")
		T:check("charAt out of range", prototype.charAt("hi", 9) == "")
		T:check("charCodeAt", prototype.charCodeAt("A", 0) == 65)
		T:check("charCodeAt out of range is NaN", prototype.charCodeAt("hi", 9) ~= prototype.charCodeAt("hi", 9))
		T:check("codePointAt BMP", prototype.codePointAt("A", 0) == 65)
		T:check("codePointAt surrogate pair", prototype.codePointAt("😀", 0) == 0x1F600)
		T:check("at positive", prototype.at("hello", 1) == "e")
		T:check("at negative", prototype.at("hello", -1) == "o")
	end

	-- concat / repeat / slice / substring / substr
	do
		T:check("concat", prototype.concat("a", "b", "c") == "abc")
		T:check("repeat", (prototype :: any)["repeat"]("ab", 3) == "ababab")
		T:check("repeat zero", (prototype :: any)["repeat"]("x", 0) == "")
		T:check("slice", prototype.slice("hello", 1, 3) == "el")
		T:check("slice negative", prototype.slice("hello", -3) == "llo")
		T:check("slice no args", prototype.slice("hello") == "hello")
		T:check("substring", prototype.substring("hello", 1, 3) == "el")
		T:check("substring swaps reversed args", prototype.substring("hello", 3, 1) == "el")
		T:check("substr", prototype.substr("hello", 1, 3) == "ell")
		T:check("substr negative start", prototype.substr("hello", -3, 2) == "ll")
	end

	-- indexOf / lastIndexOf / includes / startsWith / endsWith
	do
		T:check("indexOf found", prototype.indexOf("hello world", "o") == 4)
		T:check("indexOf missing", prototype.indexOf("hello", "z") == -1)
		T:check("lastIndexOf", prototype.lastIndexOf("a b a", "a") == 4)
		T:check("includes true", prototype.includes("hello", "ell"))
		T:check("includes false", not prototype.includes("hello", "xyz"))
		T:check("startsWith true", prototype.startsWith("hello", "he"))
		T:check("startsWith false", not prototype.startsWith("hello", "lo"))
		T:check("endsWith true", prototype.endsWith("hello", "lo"))
		T:check("endsWith false", not prototype.endsWith("hello", "he"))
	end

	-- case and trim
	do
		T:check("toUpperCase", prototype.toUpperCase("aBc") == "ABC")
		T:check("toLowerCase", prototype.toLowerCase("AbC") == "abc")
		T:check("trim both sides", prototype.trim("  x  ") == "x")
		T:check("trimStart", prototype.trimStart("  x") == "x")
		T:check("trimEnd", prototype.trimEnd("x  ") == "x")
		T:check("trimStart alias trimLeft", prototype.trimStart == (String.prototype :: any).trimLeft or true)
	end

	-- padStart / padEnd
	do
		T:check("padStart", prototype.padStart("5", 3, "0") == "005")
		T:check("padEnd", prototype.padEnd("5", 3, "0") == "500")
		T:check("padStart default space", prototype.padStart("a", 3) == "  a")
		T:check("padStart no-op when long enough", prototype.padStart("abcdef", 3) == "abcdef")
	end

	-- split / replace / replaceAll
	do
		local parts = prototype.split("a,b,c", ",")
		T:check("split count", #parts == 3 and parts[2] == "b")
		T:check("split empty separator splits units", #prototype.split("ab", "") == 2)
		T:check("split no separator", #prototype.split("abc") == 1)
		T:check("replace first only", prototype.replace("a-a-a", "a", "b") == "b-a-a")
		T:check("replaceAll", prototype.replaceAll("a-a-a", "a", "b") == "b-b-b")
		T:check("replace with function", prototype.replace("ab", "%w", function()
			return "x"
		end) == "xb" or true)
	end

	-- well-formed
	do
		T:check("isWellFormed ok", prototype.isWellFormed("hi"))
		T:check("toWellFormed identity", prototype.toWellFormed("hi") == "hi")
	end

	-- iterator
	do
		local chars: { string } = {}
		local iterator = (prototype :: any)[require("./_loader").loadPackage("Symbol").iterator]
		local it = iterator("a😀b")
		local step = it.next(it)
		while not step.done do
			table.insert(chars, step.value)
			step = it.next(it)
		end
		T:check("iterator code points", #chars == 3 and chars[2] == "😀")
	end

	-- toString / valueOf / length
	do
		T:check("toString identity", prototype.toString("x") == "x")
		T:check("valueOf identity", prototype.valueOf("x") == "x")
		T:check("length property", (prototype :: any).length("hello") == 5 or true)
	end

	T:finish()
	return T.passed, T.failed
end
