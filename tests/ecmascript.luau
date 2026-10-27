--!strict
-- ECMAScript abstract operations: the shared conversion helpers.

local loader = require("./_loader")
local T = require("./_init").new("ECMAScript")

local ECMAScript = loader.loadPackage("ECMAScript") :: any

return function(): (number, number)
	-- ToBoolean (regression: 0 and -0 must be falsy)
	do
		for _, falsy in { nil, false, 0, -0, 0 / 0, "" } do
			T:check(`{tostring(falsy)} falsy`, not ECMAScript.ToBoolean(falsy))
		end
		T:check("1 truthy", ECMAScript.ToBoolean(1))
		T:check("empty table truthy", ECMAScript.ToBoolean({}))
		T:check("nonempty string truthy", ECMAScript.ToBoolean("x"))
	end

	-- SameValue / SameValueZero
	do
		T:check("SameValue NaN equals NaN", ECMAScript.SameValue(0 / 0, 0 / 0))
		T:check("SameValueZero NaN equals NaN", ECMAScript.SameValueZero(0 / 0, 0 / 0))
		T:check("SameValue distinguishes zeros", not ECMAScript.SameValue(0, -0))
		T:check("SameValueZero folds zeros", ECMAScript.SameValueZero(0, -0))
		T:check("SameValue number equality", ECMAScript.SameValue(1, 1))
		T:check("SameValue difference", not ECMAScript.SameValue(1, 2))
	end

	-- ToIntegerOrInfinity / ToLength
	do
		T:check("ToIntegerOrInfinity truncates", ECMAScript.ToIntegerOrInfinity(4.7) == 4)
		T:check("ToIntegerOrInfinity negative", ECMAScript.ToIntegerOrInfinity(-4.7) == -4)
		T:check("ToIntegerOrInfinity NaN is 0", ECMAScript.ToIntegerOrInfinity(0 / 0) == 0)
		T:check("ToIntegerOrInfinity Infinity stays", ECMAScript.ToIntegerOrInfinity(math.huge) == math.huge)

		T:check("ToLength clamps negative to 0", ECMAScript.ToLength(-5) == 0)
		T:check("ToLength caps at 2^53-1", ECMAScript.ToLength(2 ^ 60) == 2 ^ 53 - 1)
		T:check("ToLength normal value", ECMAScript.ToLength(10.5) == 10)
	end

	-- ToAbsoluteIndex / ToClampedIndex
	do
		T:check("ToAbsoluteIndex positive", ECMAScript.ToAbsoluteIndex(2, 5) == 2)
		T:check("ToAbsoluteIndex from end", ECMAScript.ToAbsoluteIndex(-1, 5) == 4)
		T:check("ToAbsoluteIndex beyond length", ECMAScript.ToAbsoluteIndex(7, 5) == 7)
	end

	-- fixed-size integer conversions
	do
		T:check("ToUint8 wraps", ECMAScript.ToUint8(256) == 0)
		T:check("ToUint8 clamp style", ECMAScript.ToUint8Clamp(300) == 255)
		T:check("ToUint8Clamp negative", ECMAScript.ToUint8Clamp(-5) == 0)
		T:check("ToUint8Clamp half rounds up", ECMAScript.ToUint8Clamp(1.5) == 2)
		T:check("ToInt8 negative", ECMAScript.ToInt8(-1) == -1)
		T:check("ToInt8 wrap", ECMAScript.ToInt8(128) == -128)
		T:check("ToInt32 wrap", ECMAScript.ToInt32(2 ^ 31) == -2 ^ 31)
		T:check("ToUint32 wrap", ECMAScript.ToUint32(-1) == 2 ^ 32 - 1)
		T:check("ToInt16 wrap", ECMAScript.ToInt16(2 ^ 15) == -2 ^ 15)
		T:check("ToUint16 wrap", ECMAScript.ToUint16(-1) == 65535)
	end

	-- ToString
	do
		T:check("ToString nil", ECMAScript.ToString(nil) == "undefined")
		T:check("ToString boolean", ECMAScript.ToString(true) == "true")
		T:check("ToString number", ECMAScript.ToString(42) == "42")
		T:check("ToString string identity", ECMAScript.ToString("x") == "x")
		T:check("ToString array joins", ECMAScript.ToString({ 1, 2 }) == "1,2")
		T:check("ToString object", ECMAScript.ToString({}) ~= nil)
		local custom = setmetatable({}, { __index = {
			toString = function(_self)
				return "custom"
			end,
		} })
		T:check("ToString uses toString method", ECMAScript.ToString(custom) == "custom")
	end

	-- IsCallable / RequireObjectCoercible
	do
		T:check("IsCallable function", ECMAScript.IsCallable(function() end))
		T:check("IsCallable table false", not ECMAScript.IsCallable({}))
		T:check("RequireObjectCoercible passes strings", ECMAScript.RequireObjectCoercible("x") ~= nil)
		T:expectError("RequireObjectCoercible nil throws", function()
			ECMAScript.RequireObjectCoercible(nil)
		end)
	end

	-- ToPrimitive
	do
		local obj = setmetatable({}, {
			__index = {
				toString = function(_self)
					return "prim"
				end,
			},
		})
		T:check("ToPrimitive uses toString", ECMAScript.ToPrimitive(obj, "string") == "prim")
		T:check("ToPrimitive passes primitives through", ECMAScript.ToPrimitive(5, "number") == 5)
	end

	T:finish()
	return T.passed, T.failed
end
