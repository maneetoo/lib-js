--!strict
-- Map: construction, key semantics, iteration, groupBy, getOrInsert.

local T = require("./_init").new("Map")
local loader = require("./_loader")

local Map = loader.loadPackage("Map") :: any

return function(): (number, number)
	-- new: pairs, order, nil
	do
		local m = Map.new({ { "a", 1 }, { "b", 2 } })
		T:check("size after init", m.size == 2)
		T:check("get a", m.get(m, "a") == 1)
		T:check("empty map size", Map.new().size == 0)
		T:check("nil iterable gives empty", Map.new(nil).size == 0)

		-- duplicate keys: last value wins, position kept
		local dup = Map.new({ { "k", 1 }, { "k", 2 } })
		T:check("duplicate key value", dup.get(dup, "k") == 2)
		T:check("duplicate key size", dup.size == 1)

		T:expectError("non-entry element errors", function()
			Map.new({ 1, 2 })
		end)
	end

	-- set / get / has / delete / clear
	do
		local m = Map.new()
		m.set(m, "a", 1)
		T:check("set then get", m.get(m, "a") == 1)
		T:check("set returns map", m.set(m, "b", 2) == m)
		T:check("has present", m.has(m, "a"))
		T:check("has absent", not m.has(m, "z"))
		T:check("get absent is nil", m.get(m, "z") == nil)

		m.set(m, "a", 10)
		T:check("overwrite value", m.get(m, "a") == 10)
		T:check("size unchanged on overwrite", m.size == 2)

		T:check("delete true", m.delete(m, "a"))
		T:check("delete false for absent", not m.delete(m, "a"))
		T:check("size after delete", m.size == 1)

		m.clear(m)
		T:check("size after clear", m.size == 0)
		T:check("get after clear nil", m.get(m, "b") == nil)
	end

	-- SameValueZero key semantics
	do
		local m = Map.new()
		local nan = 0 / 0
		m.set(m, nan, "v")
		T:check("NaN key matches itself", m.get(m, nan) == "v")
		T:check("NaN key matches fresh NaN", m.get(m, 0 / 0) == "v")
		T:check("has NaN", m.has(m, 0 / 0))

		m.set(m, -0, "neg")
		T:check("-0 folds to +0", m.get(m, 0) == "neg")
		T:check("+0 matches -0 key", m.has(m, -0))

		m.set(m, nil, "nilKey")
		T:check("nil is a key", m.has(m, nil))
		T:check("nil key value", m.get(m, nil) == "nilKey")

		local t1, t2 = {}, {}
		m.set(m, t1, "ref")
		T:check("table key by reference", m.get(m, t1) == "ref")
		T:check("distinct tables are distinct keys", m.get(m, t2) == nil)
	end

	-- nil values are distinguishable from absent keys
	do
		local m = Map.new()
		m.set(m, "n", nil)
		T:check("has nil-valued key", m.has(m, "n"))
		T:check("get nil-valued key is nil", m.get(m, "n") == nil)
		T:check("size counts nil value", m.size == 1)
		T:check("delete nil-valued key", m.delete(m, "n") and m.size == 0)
	end

	-- insertion order and forEach
	do
		local m = Map.new({ { "a", 1 }, { "b", 2 }, { "c", 3 } })
		m.delete(m, "b")
		m.set(m, "d", 4)
		local order: { string } = {}
		m.forEach(m, function(_v, k)
			table.insert(order, k)
		end)
		T:check("order after delete+set", table.concat(order, ",") == "a,c,d")

		local seen: { number } = {}
		m.forEach(m, function(v, _k, map)
			T:check("forEach passes map", map == m)
			table.insert(seen, v)
		end)
		T:check("forEach values in order", seen[1] == 1 and seen[2] == 3 and seen[3] == 4)

		T:expectError("forEach non-callable errors", function()
			m.forEach(m, 5)
		end)
	end

	-- keys / values / entries iterators
	do
		local m = Map.new({ { "a", 1 }, { "b", 2 } })
		local it = m.keys(m)
		local first = it.next(it)
		T:check("iterator first key", first.value == "a" and not first.done)
		it.next(it)
		local last = it.next(it)
		T:check("iterator done", last.done)

		local pairs_ = {}
		local entryIt = m.entries(m)
		local step = entryIt.next(entryIt)
		while not step.done do
			table.insert(pairs_, `{step.value[1]}={step.value[2]}`)
			step = entryIt.next(entryIt)
		end
		T:check("entries pairs", table.concat(pairs_, ",") == "a=1,b=2")

		local vIt = m.values(m)
		T:check("values iterator", vIt.next(vIt).value == 1)
	end

	-- iterator over Map as iterable
	do
		local source = Map.new({ { "a", 1 }, { "b", 2 } })
		local copy = Map.new(source)
		T:check("Map as iterable copy", copy.size == 2 and copy.get(copy, "a") == 1)
	end

	-- groupBy
	do
		local items = {
			{ name = "a", type_ = "x" },
			{ name = "b", type_ = "y" },
			{ name = "c", type_ = "x" },
		}
		local grouped = Map.groupBy(items, function(item)
			return item.type_
		end)
		T:check("groupBy size", grouped.size == 2)
		T:check("groupBy bucket x", #grouped.get(grouped, "x") == 2)
		T:check("groupBy bucket y", #grouped.get(grouped, "y") == 1)
		T:check("groupBy order", grouped.get(grouped, "x")[1].name == "a")

		-- object identity keys survive mutation
		local restock = {}
		local byFlag = Map.groupBy(items, function(item)
			return if item.name == "a" then restock else items
		end)
		T:check("identity key retrieves", #byFlag.get(byFlag, restock) == 1)
		restock.extra = true
		T:check("mutated key still retrieves", #byFlag.get(byFlag, restock) == 1)

		T:check("groupBy nil items empty", Map.groupBy(nil, function() end).size == 0)
		T:expectError("groupBy non-callable errors", function()
			Map.groupBy({ 1 }, "nope")
		end)

		-- callback receives 1-based index
		local indices: { number } = {}
		Map.groupBy({ "p", "q" }, function(_v, index)
			table.insert(indices, index)
			return index
		end)
		T:check("groupBy 1-based index", indices[1] == 1 and indices[2] == 2)
	end

	-- getOrInsert
	do
		local m = Map.new({ { "a", 1 } })
		T:check("getOrInsert existing untouched", m.getOrInsert(m, "a", 99) == 1)
		T:check("existing not overwritten", m.get(m, "a") == 1)
		T:check("getOrInsert inserts default", m.getOrInsert(m, "b", 2) == 2)
		T:check("inserted readable", m.get(m, "b") == 2)
		T:check("size after insert", m.size == 2)

		m.set(m, "n", nil)
		T:check("nil-valued entry present", m.getOrInsert(m, "n", "x") == nil)
		T:check("nil entry not overwritten", m.has(m, "n") and m.get(m, "n") == nil)

		local order: { string } = {}
		m.forEach(m, function(_v, k)
			table.insert(order, k)
		end)
		T:check("insertion order for getOrInsert", table.concat(order, ",") == "a,b,n")

		local nan = 0 / 0
		T:check("getOrInsert NaN key", m.getOrInsert(m, nan, "v") == "v")
		T:check("getOrInsert NaN again", m.getOrInsert(m, nan, "w") == "v")
		T:check("-0/+0 same entry", m.getOrInsert(m, -0, "first") == m.getOrInsert(m, 0, "second"))

		local t = {}
		T:check("table key getOrInsert", m.getOrInsert(m, t, {}) ~= nil)
		local stored = m.get(m, t)
		T:check("table key identity", m.getOrInsert(m, t, {}) == stored)
	end

	-- getOrInsertComputed
	do
		local m = Map.new({ { "a", 1 } })

		-- existing key: callback never runs
		local calls = 0
		T:check("getOrInsertComputed existing", m.getOrInsertComputed(m, "a", function()
			calls += 1
			return 99
		end) == 1)
		T:check("callback not invoked on hit", calls == 0)

		-- absent key: computed value inserted and returned
		T:check("getOrInsertComputed inserts", m.getOrInsertComputed(m, "b", function()
			calls += 1
			return "computed"
		end) == "computed")
		T:check("callback ran once", calls == 1)
		T:check("computed value stored", m.get(m, "b") == "computed")

		-- the callback receives the key
		local receivedKey
		m.getOrInsertComputed(m, "k", function(key)
			receivedKey = key
			return nil
		end)
		T:check("callback receives the key", receivedKey == "k")

		-- second call does not re-run the callback
		T:check("getOrInsertComputed hit after insert", m.getOrInsertComputed(m, "b", function()
			calls += 1
			return "never"
		end) == "computed")
		T:check("callback still ran once", calls == 1)

		-- nil-valued entry counts as present
		m.set(m, "n", nil)
		T:check("nil-valued entry skips compute", m.getOrInsertComputed(m, "n", function()
			error("must not run")
		end) == nil)

		local w = Map.new()
		local result = w.getOrInsertComputed(w, "x", function(key)
			w.set(w, key, "callback-inserted")
			return "computed-value"
		end)
		T:check("callback result overwrites inserted entry", result == "computed-value")
		T:check("stored value is the callback's result", w.get(w, "x") == "computed-value")
		T:check("size did not double", w.size == 1)

		-- an error thrown by the callback propagates, inserting nothing
		local e = Map.new()
		local ok = pcall(function()
			e.getOrInsertComputed(e, "x", function()
				error("compute failed")
			end)
		end)
		T:check("callback error propagates", not ok)
		T:check("nothing inserted on error", not e.has(e, "x") and e.size == 0)

		-- non-callable throws TypeError before any lookup
		T:expectError("getOrInsertComputed non-callable", function()
			m.getOrInsertComputed(m, "a", "not a function")
		end)

		-- key semantics: NaN, -0, nil
		local k = Map.new()
		T:check("getOrInsertComputed NaN key", k.getOrInsertComputed(k, 0 / 0, function()
			return "nan"
		end) == "nan")
		T:check("getOrInsertComputed NaN again", k.getOrInsertComputed(k, 0 / 0, function()
			return "other"
		end) == "nan")
		k.getOrInsertComputed(k, -0, function()
			return "zero"
		end)
		T:check("getOrInsertComputed -0 folds to +0", k.getOrInsertComputed(k, 0, function()
			return "plus"
		end) == "zero")
		T:check("getOrInsertComputed nil key", k.getOrInsertComputed(k, nil, function()
			return "under-nil"
		end) == "under-nil")
	end

	T:finish()
	return T.passed, T.failed
end
