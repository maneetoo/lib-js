--!strict
-- Boolean: ToBoolean coercion and prototype.

local loader = require("./_loader")
local T = require("./_init").new("Boolean")

local Boolean = loader.loadPackage("Boolean") :: any

return function(): (number, number)
	-- ToBoolean: exactly JS's falsy set
	do
		local falsy = { nil, false, 0, -0, 0 / 0, "" }
		for _, value in falsy do
			T:check(`{tostring(value)} is falsy`, not Boolean(value))
		end
		local truthy: { any } = { true, 1, -1, 0.5, "a", " ", "0", {}, { 0 }, function() end }
		for _, value in truthy do
			T:check(`{type(value)} truthy value is truthy`, Boolean(value) == true)
		end
		-- empty table is truthy, unlike Lua's own truthiness rules
		T:check("empty table truthy (JS parity)", Boolean({}) == true)
	end

	-- prototype
	do
		T:check("prototype has toString", type(Boolean.prototype.toString) == "function")
		T:check("prototype has valueOf", type(Boolean.prototype.valueOf) == "function")
		T:check("toString true", Boolean.prototype.toString(true) == "true")
		T:check("toString false", Boolean.prototype.toString(false) == "false")
		T:check("valueOf identity", Boolean.prototype.valueOf(true) == true)
	end

	T:finish()
	return T.passed, T.failed
end
