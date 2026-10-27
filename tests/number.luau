--!strict
-- Number: type predicates, constants, parsing, prototype.

local loader = require("./_loader")
local T = require("./_init").new("Number")

local Number = loader.loadPackage("Number") :: any

return function(): (number, number)
	-- constants
	do
		T:check("EPSILON", Number.EPSILON == 2 ^ -52)
		T:check("MAX_SAFE_INTEGER", Number.MAX_SAFE_INTEGER == 2 ^ 53 - 1)
		T:check("MIN_SAFE_INTEGER", Number.MIN_SAFE_INTEGER == -(2 ^ 53 - 1))
		T:check("MAX_VALUE finite", Number.MAX_VALUE < math.huge)
		T:check("POSITIVE_INFINITY", Number.POSITIVE_INFINITY == math.huge)
		T:check("NEGATIVE_INFINITY", Number.NEGATIVE_INFINITY == -math.huge)
		T:check("NaN self-unequal", Number.NaN ~= Number.NaN)
	end

	-- isNaN / isFinite / isInteger / isSafeInteger
	do
		T:check("isNaN true", Number.isNaN(0 / 0))
		T:check("isNaN false for numbers", not Number.isNaN(5))
		T:check("isNaN false for nil", not Number.isNaN(nil))
		T:check("isNaN false for strings", not Number.isNaN("NaN"))

		T:check("isFinite true", Number.isFinite(42))
		T:check("isFinite false for Infinity", not Number.isFinite(math.huge))
		T:check("isFinite false for NaN", not Number.isFinite(0 / 0))
		T:check("isFinite false for nil", not Number.isFinite(nil))
		T:check("isFinite false for string", not Number.isFinite("42"))

		T:check("isInteger true", Number.isInteger(7))
		T:check("isInteger false for 7.5", not Number.isInteger(7.5))
		T:check("isInteger false for nil", not Number.isInteger(nil))
		T:check("isInteger true for -0", Number.isInteger(-0))

		T:check("isSafeInteger true", Number.isSafeInteger(2 ^ 53 - 1))
		T:check("isSafeInteger false beyond", not Number.isSafeInteger(2 ^ 53))
		T:check("isSafeInteger false for float", not Number.isSafeInteger(1.5))
		T:check("isSafeInteger false for nil", not Number.isSafeInteger(nil))
	end

	-- parseFloat
	do
		T:check("parseFloat simple", Number.parseFloat("3.14") == 3.14)
		T:check("parseFloat leading space", Number.parseFloat("  42") == 42)
		T:check("parseFloat trailing junk", Number.parseFloat("12abc") == 12)
		T:check("parseFloat sign", Number.parseFloat("-2.5") == -2.5)
		T:check("parseFloat Infinity", Number.parseFloat("Infinity") == math.huge)
		T:check("parseFloat junk is NaN", Number.isNaN(Number.parseFloat("abc")))
		T:check("parseFloat empty is NaN", Number.isNaN(Number.parseFloat("")))
	end

	-- parseInt
	do
		T:check("parseInt decimal", Number.parseInt("42") == 42)
		T:check("parseInt radix 16", Number.parseInt("ff", 16) == 255)
		T:check("parseInt 0x prefix", Number.parseInt("0x10") == 16)
		T:check("parseInt leading space", Number.parseInt(" 7") == 7)
		T:check("parseInt junk is NaN", Number.isNaN(Number.parseInt("zz")))
		T:check("parseInt radix 2", Number.parseInt("101", 2) == 5)
	end

	-- prototype toString / valueOf / toFixed / toPrecision
	do
		T:check("toString decimal", Number.prototype.toString(42) == "42")
		T:check("toString radix", Number.prototype.toString(255, 16) == "ff")
		T:check("toString fraction", Number.prototype.toString(0.5) == "0.5")
		T:check("valueOf identity", Number.prototype.valueOf(9) == 9)
		T:check("toFixed", Number.prototype.toFixed(3.14159, 2) == "3.14")
		T:check("toFixed pads", Number.prototype.toFixed(1, 2) == "1.00")
	end

	T:finish()
	return T.passed, T.failed
end
