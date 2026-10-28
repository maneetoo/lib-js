--!strict
-- Set: membership, key semantics, iteration, set algebra.

local T = require("./_init").new("Set")
local loader = require("./_loader")

local Set = loader.loadPackage("Set") :: any

local function toList(set: any): { string }
	local list: { string } = {}
	set.forEach(set, function(value)
		table.insert(list, tostring(value))
	end)
	table.sort(list)
	return list
end

return function(): (number, number)
	-- add / has / delete / clear / size
	do
		local s = Set.new()
		s.add(s, "a")
		T:check("add then has", s.has(s, "a"))
		T:check("size 1", s.size == 1)
		T:check("add returns set", s.add(s, "b") == s)
		s.add(s, "a")
		T:check("duplicate add keeps size", s.size == 2)
		T:check("has absent", not s.has(s, "z"))
		T:check("delete true", s.delete(s, "a"))
		T:check("delete absent false", not s.delete(s, "a"))
		T:check("size after delete", s.size == 1)
		s.clear(s)
		T:check("size after clear", s.size == 0)
	end

	-- SameValueZero membership
	do
		local s = Set.new()
		s.add(s, 0 / 0)
		T:check("NaN matches itself", s.has(s, 0 / 0))
		T:check("fresh NaN matches", s.has(s, 0 / 0))
		s.add(s, -0)
		T:check("-0 folds to +0", s.has(s, 0))
		T:check("+0 matches -0", s.has(s, -0))
		s.add(s, nil)
		T:check("nil is a member", s.has(s, nil))
		local t = {}
		s.add(s, t)
		T:check("table by reference", s.has(s, t) and not s.has(s, {}))
	end

	-- init from iterable and insertion order
	do
		local s = Set.new({ "b", "a", "b", "c" })
		T:check("init dedupes", s.size == 3)
		local list = {}
		s.forEach(s, function(v)
			table.insert(list, tostring(v))
		end)
		T:check("insertion order kept", table.concat(list, ",") == "b,a,c")

		local fromSet = Set.new(s)
		T:check("Set as iterable", fromSet.size == 3)
		T:check("empty init", Set.new().size == 0)
		T:check("nil init", Set.new(nil).size == 0)
	end

	-- keys/values/entries
	do
		local s = Set.new({ "x", "y" })
		local it = s.values(s)
		T:check("values iterator", it.next(it).value == "x")
		local eIt = s.entries(s)
		local pair = eIt.next(eIt).value
		T:check("entries pairs value twice", pair[1] == pair[2])
		T:check("keys equals values", s.keys(s).next(s.keys(s)).value == "x")
	end

	-- set algebra
	do
		local a = Set.new({ 1, 2, 3 })
		local b = Set.new({ 2, 3, 4 })

		T:check("union", toList(a.union(a, b))[1] == "1" and a.union(a, b).size == 4)
		T:check("intersection size", a.intersection(a, b).size == 2)
		T:check("intersection members", a.intersection(a, b).has(a.intersection(a, b), 2))
		T:check("difference size", a.difference(a, b).size == 1)
		T:check(
			"difference member",
			a.difference(a, b).has(a.difference(a, b), 1) and not a.difference(a, b).has(a.difference(a, b), 2)
		)
		T:check("symmetricDifference size", a.symmetricDifference(a, b).size == 2)

		T:check("isSubsetOf false", not a.isSubsetOf(a, b))
		T:check("subset true", Set.new({ 2, 3 }).isSubsetOf(Set.new({ 2, 3 }), a))
		T:check("isSupersetOf true", a.isSupersetOf(a, Set.new({ 1, 2 })))
		T:check("isDisjointFrom true", Set.new({ 1 }).isDisjointFrom(Set.new({ 1 }), Set.new({ 5 })))
		T:check("isDisjointFrom false", not Set.new({ 1 }).isDisjointFrom(Set.new({ 1 }), a))

		-- plain arrays are NOT set-like (JS parity: TypeError)
		T:expectError("union with plain array errors", function()
			a.union(a, { 5 })
		end)
		-- a custom set-like object works, as in JS
		local setLike = {
			size = 2,
			has = function(_self, v)
				return v == 1 or v == 2
			end,
			keys = function(_self)
				local values = { 1, 2 }
				local i = 0
				local it = {}
				it.next = function(_it)
					i += 1
					return { value = values[i], done = i > 2 }
				end
				return it
			end,
		}
		T:check("custom set-like isSubsetOf", Set.new({ 1, 2 }).isSubsetOf(Set.new({ 1, 2 }), setLike))
		T:check("custom set-like union size", a.union(a, setLike).size == 3)

		-- algebra does not mutate
		T:check("union does not mutate", a.size == 3)
	end

	-- forEach errors
	do
		local s = Set.new({ 1 })
		T:expectError("forEach non-callable", function()
			s.forEach(s, "x")
		end)
	end

	T:finish()
	return T.passed, T.failed
end
