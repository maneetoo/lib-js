--!strict
-- Math: constants and the non-trivial ported functions.

local loader = require("./_loader")
local T = require("./_init").new("Math")

local Math = loader.loadPackage("Math") :: any

local function near(a: number, b: number, tolerance: number?): boolean
	local eps = tolerance or 1e-12
	return math.abs(a - b) <= eps
end

return function(): (number, number)
	-- constants
	do
		T:check("PI", Math.PI == math.pi)
		T:check("E", near(Math.E, 2.718281828459045, 1e-15))
		T:check("LN10", near(Math.LN10, math.log(10), 1e-14))
		T:check("SQRT2", near(Math.SQRT2, math.sqrt(2), 1e-15))
		T:check("SQRT1_2", near(Math.SQRT1_2, math.sqrt(0.5), 1e-15))
		T:check("LOG2E", near(Math.LOG2E, 1 / math.log(2), 1e-14))
		T:check("LOG10E", near(Math.LOG10E, 1 / math.log(10), 1e-14))
	end

	-- sign
	do
		T:check("sign positive", Math.sign(5) == 1)
		T:check("sign negative", Math.sign(-5) == -1)
		T:check("sign zero", Math.sign(0) == 0)
		T:check("sign -0 is -0", 1 / Math.sign(-0) == -math.huge)
		T:check("sign NaN", Math.sign(0 / 0) ~= Math.sign(0 / 0))
	end

	-- trunc
	do
		T:check("trunc positive", Math.trunc(4.7) == 4)
		T:check("trunc negative", Math.trunc(-4.7) == -4)
		T:check("trunc integer", Math.trunc(4) == 4)
		T:check("trunc -0", 1 / Math.trunc(-0.1) == -math.huge)
	end

	-- cbrt
	do
		T:check("cbrt positive", near(Math.cbrt(27), 3, 1e-12))
		T:check("cbrt negative", near(Math.cbrt(-27), -3, 1e-12))
		T:check("cbrt zero", Math.cbrt(0) == 0)
	end

	-- hypot
	do
		T:check("hypot 3-4-5", near(Math.hypot(3, 4), 5, 1e-12))
		T:check("hypot single", Math.hypot(5) == 5)
		T:check("hypot empty", Math.hypot() == 0)
		T:check("hypot overflow safe", Math.hypot(1e200, 1e200) ~= math.huge)
	end

	-- imul / clz32
	do
		T:check("imul small", Math.imul(3, 4) == 12)
		T:check("imul negative", Math.imul(-1, -1) == 1)
		T:check("imul 32-bit wrap", Math.imul(0xffffffff, 2) == -2)
		T:check("clz32 zero", Math.clz32(0) == 32)
		T:check("clz32 one", Math.clz32(1) == 31)
		T:check("clz32 large", Math.clz32(0x80000000) == 0)
	end

	-- log2 / log1p / expm1 / asinh / acosh / atanh
	do
		T:check("log2 8", near(Math.log2(8), 3, 1e-12))
		T:check("log1p small", near(Math.log1p(1e-10), 1e-10, 1e-16))
		T:check("expm1 small", near(Math.expm1(1e-10), 1e-10, 1e-16))
		T:check("asinh symmetric", near(Math.asinh(1), -Math.asinh(-1), 1e-12))
		T:check("acosh domain", Math.acosh(0) ~= Math.acosh(0))
		T:check("atanh domain", Math.atanh(1) == math.huge)
	end

	-- pow / fround / round / min / max
	do
		T:check("pow squares", Math.pow(2, 10) == 1024)
		T:check("pow negative exponent", near(Math.pow(4, -1), 0.25, 1e-15))
		T:check("pow zero", Math.pow(5, 0) == 1)
		T:check("fround precision loss", Math.fround(0.1) ~= 0.1)
		T:check("fround identity for float32", Math.fround(0.5) == 0.5)
		T:check("round half up", Math.round(2.5) == 3)
		T:check("round half down", Math.round(-2.5) == -2)
		T:check("round negative half-up", Math.round(1.5) == 2)
		T:check("min", Math.min(1, 2, 3) == 1)
		T:check("max", Math.max(1, 2, 3) == 3)
		T:check("min no args is Infinity", Math.min() == math.huge)
		T:check("max no args is -Infinity", Math.max() == -math.huge)
		T:check("min with NaN", Math.min(1, 0 / 0) ~= Math.min(1, 0 / 0))
	end

	T:finish()
	return T.passed, T.failed
end
