--!strict
-- instanceof: prototype-chain membership. globalThis: the global table.

local loader = require("./_loader")
local T = require("./_init").new("instanceof")

local instanceof = loader.loadPackage("instanceof") :: any
local globalThis = loader.loadPackage("globalThis") :: any

return function(): (number, number)
	-- classic class instance
	do
		local MyClass = {}
		MyClass.__index = MyClass
		function MyClass.new()
			return setmetatable({}, MyClass)
		end
		local instance = MyClass.new()
		T:check("instance of class", instanceof(instance, MyClass))
		T:check("class not instance of itself", not instanceof(MyClass, MyClass))

		local Other = {}
		Other.__index = Other
		T:check("unrelated class false", not instanceof(instance, Other))
	end

	-- multi-level chain
	do
		local A, B = {}, {}
		A.__index = A
		B.__index = B
		setmetatable(B, { __index = A })
		local b = setmetatable({}, B)
		T:check("direct prototype", instanceof(b, B))
		T:check("inherited prototype", instanceof(b, A))

		-- cyclic chain terminates
		local C = {}
		C.__index = C
		setmetatable(C, { __index = C })
		T:check("cyclic chain terminates false", not instanceof({}, C))
	end

	-- primitives and nil
	do
		T:check("number never instance", not instanceof(5, {}))
		T:check("nil never instance", not instanceof(nil, {}))
		T:check("string never instance", not instanceof("x", {}))
	end

	-- globalThis
	do
		T:check("globalThis is a table", type(globalThis) == "table")
		-- writes through it change the global scope
		local g = globalThis :: any
		-- selene: allow(global_usage)
		-- (testing _G itself is the point of the globalThis suite)
		local globals = _G :: any
		g.__libjs_test_marker = 42
		T:check("write via globalThis visible in _G", globals.__libjs_test_marker == 42)
		globals.__libjs_test_marker = nil
		T:check("cleanup works", globals.__libjs_test_marker == nil)
	end

	T:finish()
	return T.passed, T.failed
end
