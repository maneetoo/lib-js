--!strict
-- Object: statics and prototype methods.

local T = require("./_init").new("Object")
local loader = require("./_loader")

local Object = loader.loadPackage("Object") :: any
local Symbol = loader.loadPackage("Symbol") :: any

return function(): (number, number)
	-- assign: own-key copy, nil sources skipped, symbol keys copied
	do
		local sym = Symbol("s")
		local target = { existing = "kept" }
		local source = { a = 1, b = 2 }
		source[sym] = 3
		local result = Object.assign(target, nil, source)
		T:check("assign returns the target", result == target)
		T:check("assign copies string keys", target.a == 1 and target.b == 2)
		T:check("assign keeps pre-existing keys", target.existing == "kept")
		T:check("assign copies symbol keys", target[sym] == 3)
		local later = Object.assign(target, { a = 9 })
		T:check("later sources overwrite", later.a == 9)
	end

	-- keys / values / entries / getOwnPropertyNames: own, non-symbol
	do
		local sym = Symbol("k")
		local t = { x = 1, y = 2 }
		t[sym] = 3
		T:check("keys count", #Object.keys(t) == 2)
		T:check("values count", #Object.values(t) == 2)
		T:check("entries count", #Object.entries(t) == 2)
		T:check("getOwnPropertyNames count", #Object.getOwnPropertyNames(t) == 2)
		T:check("getOwnPropertySymbols finds symbol keys", #Object.getOwnPropertySymbols(t) == 1)

		local valuesSum = 0
		for _, v in Object.values(t) do
			valuesSum += v
		end
		T:check("values sum", valuesSum == 3)
		local byKey = {}
		for _, pair in Object.entries(t) do
			byKey[pair[1]] = pair[2]
		end
		T:check("entries pairs round-trip", byKey.x == 1 and byKey.y == 2)
	end

	-- freeze / isFrozen / seal-as-freeze paths
	do
		local frozen = Object.freeze({ a = 1 })
		T:check("isFrozen true", Object.isFrozen(frozen))
		T:check("frozen implies sealed", Object.isSealed(frozen))
		T:check("frozen is not extensible", not Object.isExtensible(frozen))
		T:check("isFrozen on primitive", Object.isFrozen(1))
		T:check("isSealed on primitive", Object.isSealed("x"))
		T:check("plain table is extensible", Object.isExtensible({}))
		T:check("plain table not frozen", not Object.isFrozen({}))

		local t = { a = 1 }
		Object.freeze(t)
		T:expectError("write to frozen table errors", function()
			t.a = 2
		end)
	end

	-- seal: adds forbidden, values writable
	do
		local t = { a = 1, b = 2 }
		Object.seal(t)
		T:check("isSealed true", Object.isSealed(t))
		T:check("sealed not frozen", not Object.isFrozen(t))
		T:check("sealed not extensible", not Object.isExtensible(t))
		t.a = 10
		T:check("sealed value writable", t.a == 10)
		T:expectError("add key to sealed errors", function()
			t.c = 3
		end)
		Object.seal(t)
		T:check("double seal is a no-op", Object.isSealed(t))

		T:check("seal returns same table", Object.seal(t) == t)
		T:check("preventExtensions alone is not sealed", not Object.isSealed(Object.preventExtensions({})))
	end

	-- preventExtensions / isExtensible
	do
		local t = { a = 1 }
		Object.preventExtensions(t)
		T:check("not extensible", not Object.isExtensible(t))
		T:check("existing value writable", t.a == 1)
		t.a = 5
		T:check("write to existing key works", t.a == 5)
		T:expectError("add key errors", function()
			t.b = 2
		end)
		T:check("preventExtensions returns same table", Object.preventExtensions(t) == t)
	end

	-- defineProperty / defineProperties / descriptors
	do
		local t = {}
		Object.defineProperty(t, "x", { value = 1 })
		T:check("defineProperty stores value", t.x == 1)
		T:check("defineProperty returns object", Object.defineProperty(t, "y", { value = 2 }) == t)
		T:expectError("accessor descriptors rejected", function()
			Object.defineProperty(t, "z", { get = function() end })
		end)

		Object.defineProperties(t, { a = { value = 10 }, b = { value = 20 } })
		T:check("defineProperties stores values", t.a == 10 and t.b == 20)

		local d = Object.getOwnPropertyDescriptor(t, "a")
		T:check("descriptor has value", d.value == 10)
		T:check("descriptor enumerable true", d.enumerable == true)
		T:check("descriptor writable true", d.writable == true)
		T:check("descriptor of missing key nil", Object.getOwnPropertyDescriptor(t, "nope") == nil)

		local all = Object.getOwnPropertyDescriptors(t)
		T:check("descriptors plural counts keys", all.x ~= nil and all.a ~= nil and all.b ~= nil)

		local frozen = Object.freeze({ q = 1 })
		local fd = Object.getOwnPropertyDescriptor(frozen, "q")
		T:check("frozen descriptor not writable", fd.writable == false)
		T:check("frozen descriptor not configurable", fd.configurable == false)

		T:expectError("defineProperty new key on frozen", function()
			Object.defineProperty(frozen, "new", { value = 1 })
		end)
		T:expectError("defineProperty different value on frozen", function()
			Object.defineProperty(frozen, "q", { value = 2 })
		end)
	end

	-- getPrototypeOf / setPrototypeOf / create
	do
		local proto = { greet = "hi" }
		local o = Object.create(proto)
		T:check("create links prototype", o.greet == "hi")
		T:check("getPrototypeOf returns link", Object.getPrototypeOf(o) == proto)
		T:check("create(null) has no prototype", Object.getPrototypeOf(Object.create(nil)) == nil)

		local o2 = Object.setPrototypeOf({}, proto)
		T:check("setPrototypeOf links", o2.greet == "hi")
		T:check("setPrototypeOf returns object", Object.setPrototypeOf(o2, nil) == o2)
		T:check("prototype removed", Object.getPrototypeOf(o2) == nil)

		local a, b = {}, {}
		Object.setPrototypeOf(a, b)
		T:expectError("cyclic chain rejected", function()
			Object.setPrototypeOf(b, a)
		end)

		local sealed = Object.seal({})
		T:expectError("setPrototypeOf on non-extensible", function()
			Object.setPrototypeOf(sealed, {})
		end)
		T:expectError("setPrototypeOf on frozen", function()
			Object.setPrototypeOf(Object.freeze({}), {})
		end)

		local withProps = Object.create(proto, { p = { value = 42 } })
		T:check("create with properties", withProps.p == 42)
		T:expectError("create rejects bad prototype", function()
			Object.create(42)
		end)
	end

	-- hasOwn / prototype methods
	do
		local proto = { inherited = 1 }
		local o = setmetatable({ own = 2 }, { __index = proto })
		T:check("hasOwn true for own", Object.hasOwn(o, "own"))
		T:check("hasOwn false for inherited", not Object.hasOwn(o, "inherited"))
		T:check("prototype.hasOwnProperty mirrors hasOwn", Object.prototype.hasOwnProperty(o, "own"))
		T:check("prototype.propertyIsEnumerable mirrors own", Object.prototype.propertyIsEnumerable(o, "own"))

		T:check("isPrototypeOf true", Object.prototype.isPrototypeOf(proto, o))
		T:check("isPrototypeOf false for stranger", not Object.prototype.isPrototypeOf({}, o))

		T:check("toString tag", Object.prototype.toString({}) == "[object Object]")
		T:check("toString number tag", Object.prototype.toString(1) == "[object Number]")
		T:check("valueOf returns self", Object.prototype.valueOf(5) == 5)
		T:expectError("valueOf nil errors", function()
			Object.prototype.valueOf(nil)
		end)
	end

	-- is: SameValue
	do
		T:check("is NaN equals NaN", Object.is(0 / 0, 0 / 0))
		T:check("is distinguishes +0/-0", not Object.is(0, -0))
		local tbl = {}
		T:check("is same table identity", Object.is(tbl, tbl))
		T:check("is identity for tables", Object.is(tbl, tbl) and not Object.is(tbl, {}))
		T:check("is primitives", Object.is("a", "a") and not Object.is("a", "b"))
	end

	-- entries / fromEntries round-trip
	do
		local original = { a = 1, b = 2, c = 3 }
		local round = Object.fromEntries(Object.entries(original))
		T:check("fromEntries round-trip", round.a == 1 and round.b == 2 and round.c == 3)
		local lastWins = Object.fromEntries({ { "k", 1 }, { "k", 2 } })
		T:check("fromEntries last wins", lastWins.k == 2)
		T:expectError("fromEntries nil key errors", function()
			Object.fromEntries({ { nil, 1 } })
		end)
	end

	-- groupBy
	do
		local items = {
			{ name = "a", type_ = "x" },
			{ name = "b", type_ = "y" },
			{ name = "c", type_ = "x" },
		}
		local grouped = Object.groupBy(items, function(item)
			return item.type_
		end)
		T:check("groupBy bucket sizes", #grouped.x == 2 and #grouped.y == 1)
		T:check("groupBy preserves order", grouped.x[1].name == "a" and grouped.x[2].name == "c")
		T:expectError("groupBy nil key errors", function()
			Object.groupBy({ 1 }, function()
				return nil
			end)
		end)
	end

	T:finish()
	return T.passed, T.failed
end
