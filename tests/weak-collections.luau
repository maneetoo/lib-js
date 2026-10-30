--!strict
-- WeakMap, WeakSet, WeakRef: weak-keyed collections.

local T = require("./_init").new("WeakMap/WeakSet/WeakRef")
local loader = require("./_loader")

local WeakMap = loader.loadPackage("WeakMap") :: any
local WeakSet = loader.loadPackage("WeakSet") :: any
local WeakRef = loader.loadPackage("WeakRef") :: any

return function(): (number, number)
	-- WeakMap basics
	do
		local wm = WeakMap.new()
		local key = {}
		wm.set(wm, key, "v")
		T:check("set then get", wm.get(wm, key) == "v")
		T:check("has key", wm.has(wm, key))
		T:check("set returns map", wm.set(wm, key, "v2") == wm)
		T:check("overwrite value", wm.get(wm, key) == "v2")
		T:check("get absent nil", wm.get(wm, {}) == nil)
		T:check("has absent false", not wm.has(wm, {}))
		T:check("delete true", wm.delete(wm, key))
		T:check("delete absent false", not wm.delete(wm, key))
		T:check("get after delete", wm.get(wm, key) == nil)

		-- key validation
		T:expectError("primitive key rejected on set", function()
			wm.set(wm, "str", 1)
		end)
		T:expectError("nil key rejected on set", function()
			wm.set(wm, nil, 1)
		end)
		T:check("get with bad key does not throw", wm.get(wm, 5) == nil)
	end

	-- WeakMap getOrInsert / getOrInsertComputed
	do
		local wm = WeakMap.new()
		local key = {}
		T:check("getOrInsert inserts", wm.getOrInsert(wm, key, "d") == "d")
		T:check("getOrInsert existing", wm.getOrInsert(wm, key, "other") == "d")

		local key2 = {}
		T:check("getOrInsertComputed computes", wm.getOrInsertComputed(wm, key2, function(k)
			return `computed:{k == key2}`
		end) == "computed:true")
		T:check("getOrInsertComputed existing skips compute", wm.getOrInsertComputed(wm, key2, function()
			return "never"
		end) == "computed:true")

		T:expectError("getOrInsert primitive key errors", function()
			wm.getOrInsert(wm, 7, "x")
		end)
		T:expectError("getOrInsertComputed non-callable", function()
			wm.getOrInsertComputed(wm, {}, "not a function")
		end)
	end

	-- WeakSet basics
	do
		local ws = WeakSet.new()
		local member = {}
		ws.add(ws, member)
		T:check("add then has", ws.has(ws, member))
		T:check("add returns set", ws.add(ws, member) == ws)
		T:check("has absent", not ws.has(ws, {}))
		T:check("delete true", ws.delete(ws, member))
		T:check("delete absent", not ws.delete(ws, member))
		T:check("has after delete", not ws.has(ws, member))

		local fromIterable = WeakSet.new({ {}, {} })
		T:check("iterable init", type(fromIterable) == "table")
		T:expectError("primitive member rejected", function()
			ws.add(ws, 42)
		end)
	end

	-- WeakRef
	do
		local target = { name = "t" }
		local ref = WeakRef.new(target)
		T:check("deref returns target", ref.deref(ref) == target)
		T:check("deref fields", ref.deref(ref).name == "t")
		T:check("deref twice stable", ref.deref(ref) == ref.deref(ref))
		T:expectError("WeakRef.new primitive errors", function()
			WeakRef.new(5)
		end)
	end

	T:finish()
	return T.passed, T.failed
end
