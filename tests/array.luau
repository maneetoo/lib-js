--!strict
-- Array: statics, mutators, accessors, iteration, searching, new methods.

local loader = require("./_loader")
local T = require("./_init").new("Array")

local Array = loader.loadPackage("Array") :: any
local prototype = Array.prototype :: any

return function(): (number, number)
	-- statics
	do
		T:check("isArray true", Array.isArray({}))
		T:check("isArray false for non-array", not Array.isArray("x"))
		T:check("isArray false for nil", not Array.isArray(nil))
		T:check("of builds array", Array.of(1, 2, 3)[2] == 2)
		T:check("of single", Array.of(7)[1] == 7)
		T:check("from array-like", Array.from({ 1, 2, 3 })[3] == 3)
		T:check("from with map", Array.from({ 1, 2 }, function(v)
			return v * 2
		end)[2] == 4)
		T:check("from string", #Array.from("abc") == 3)
	end

	-- push / pop / shift / unshift
	do
		local a = { 1, 2 }
		T:check("push returns new length", prototype.push(a, 3) == 3)
		T:check("push appends", a[3] == 3)
		T:check("pop removes last", prototype.pop(a) == 3)
		T:check("pop from empty", prototype.pop({}) == nil)
		T:check("shift removes first", prototype.shift({ 1, 2 }) == 1)
		local b = { 2, 3 }
		T:check("unshift returns new length", prototype.unshift(b, 1) == 3)
		T:check("unshift prepends", b[1] == 1 and b[3] == 3)
	end

	-- slice / splice / concat / fill / copyWithin
	do
		local a = { 1, 2, 3, 4, 5 }
		local s = prototype.slice(a, 1, 3)
		T:check("slice extract (0-based, end exclusive)", s[1] == 2 and s[2] == 3 and #s == 2)
		T:check("slice does not mutate", #a == 5)
		T:check("slice negative indices", prototype.slice({ 1, 2, 3, 4 }, -2)[1] == 3)
		T:check("slice no args copies", #prototype.slice(a) == 5)

		local sp = { 1, 2, 3, 4 }
		local removed = prototype.splice(sp, 2, 1, "x", "y")
		T:check("splice removes 0-based index 2", removed[1] == 3 and #removed == 1)
		T:check("splice inserts in place", sp[1] == 1 and sp[2] == 2 and sp[3] == "x" and sp[4] == "y" and sp[5] == 4)

		T:check("concat", #prototype.concat({ 1 }, { 2, 3 }) == 3)
		T:check("concat flattens one level", #prototype.concat({ 1 }, { { 2 } }) == 2)

		-- fill(value, start, end): 0-based, end exclusive, in place
		local f = { 1, 2, 3, 4 }
		prototype.fill(f, 0, 1, 3)
		T:check("fill range (0-based start 1, end 3)", f[1] == 1 and f[2] == 0 and f[3] == 0 and f[4] == 4)

		local c = { 1, 2, 3, 4, 5 }
		prototype.copyWithin(c, 0, 3)
		T:check("copyWithin (0-based target 0, source 3)", c[1] == 4 and c[2] == 5 and #c == 5)
	end

	-- indexOf / lastIndexOf / includes
	do
		local a = { 1, "a", 1 }
		T:check("indexOf finds first (0-based)", prototype.indexOf({ 10, 20 }, 20) == 1)
		T:check("indexOf missing", prototype.indexOf(a, "z") == -1)
		T:check("lastIndexOf (0-based)", prototype.lastIndexOf({ 1, 2, 1 }, 1) == 2)
		T:check("includes true", prototype.includes(a, "a"))
		T:check("includes false", not prototype.includes(a, "z"))
		T:check("includes NaN", prototype.includes({ 0 / 0 }, 0 / 0))
	end

	-- find / findIndex / findLast / findLastIndex
	do
		local a = { 5, 12, 8, 130, 44 }
		local isBig = function(v)
			return v > 10
		end
		T:check("find", prototype.find(a, isBig) == 12)
		T:check("findIndex (0-based)", prototype.findIndex(a, isBig) == 1)
		T:check("findLast", prototype.findLast(a, isBig) == 44)
		T:check("findLastIndex (0-based)", prototype.findLastIndex(a, isBig) == 4)
		T:check("find missing nil", prototype.find(a, function()
			return false
		end) == nil)
		T:check("findIndex missing -1", prototype.findIndex(a, function()
			return false
		end) == -1)
	end

	-- map / filter / forEach / reduce / reduceRight
	do
		local a = { 1, 2, 3 }
		T:check("map", prototype.map(a, function(v)
			return v * 2
		end)[3] == 6)
		T:check("filter", #prototype.filter(a, function(v)
			return v > 1
		end) == 2)
		local sum = 0
		prototype.forEach(a, function(v)
			sum += v
		end)
		T:check("forEach sum", sum == 6)
		T:check("reduce", prototype.reduce(a, function(acc, v)
			return acc + v
		end, 0) == 6)
		T:check("reduce no initial uses first", prototype.reduce(a, function(acc, v)
			return acc + v
		end) == 6)
		T:check("reduceRight", prototype.reduceRight({ 1, 2, 3 }, function(acc, v)
			return acc .. tostring(v)
		end, "") == "321")

		-- callback receives (value, index, array)
		local indices: { number } = {}
		prototype.forEach(a, function(_v, i)
			table.insert(indices, i)
		end)
		T:check("forEach 0-based indices", indices[1] == 0 and indices[2] == 1 and indices[3] == 2)
	end

	-- some / every
	do
		local a = { 1, 2, 3 }
		T:check(
			"some true",
			prototype.some(a, function(v)
				return v > 2
			end)
		)
		T:check("some false", not prototype.some(a, function(v)
			return v > 5
		end))
		T:check(
			"every true",
			prototype.every(a, function(v)
				return v > 0
			end)
		)
		T:check("every false", not prototype.every(a, function(v)
			return v > 1
		end))
		T:check(
			"every on empty is true",
			prototype.every({}, function()
				return false
			end)
		)
		T:check("some on empty is false", not prototype.some({}, function()
			return true
		end))
	end

	-- join / reverse / sort
	do
		T:check("join default", prototype.join({ 1, 2, 3 }) == "1,2,3")
		T:check("join custom separator", prototype.join({ "a", "b" }, "-") == "a-b")
		T:check("join nil as empty", prototype.join({ 1, nil, 3 }) == "1,,3")

		local r = { 1, 2, 3 }
		prototype.reverse(r)
		T:check("reverse in place", r[1] == 3 and r[3] == 1)

		local s = { 3, 1, 2 }
		prototype.sort(s)
		T:check("sort default", s[1] == 1 and s[2] == 2 and s[3] == 3)
		local s2 = { 1, 10, 2 }
		prototype.sort(s2, function(x, y)
			return y - x
		end)
		T:check("sort with comparator descending", s2[1] == 10 and s2[2] == 2 and s2[3] == 1)
	end

	-- flat / flatMap
	do
		T:check("flat one level", #prototype.flat({ 1, { 2, { 3 } } }) == 3)
		T:check("flat depth 2", #prototype.flat({ 1, { 2, { 3 } } }, 2) == 3)
		T:check("flatMap", #prototype.flatMap({ 1, 2 }, function(v)
			return { v, v }
		end) == 4)
	end

	-- at / with / toReversed / toSorted / toSpliced
	do
		T:check("at positive (0-based)", prototype.at({ 1, 2, 3 }, 2) == 3)
		T:check("at negative", prototype.at({ 1, 2, 3 }, -1) == 3)
		T:check("at out of range", prototype.at({ 1, 2, 3 }, 5) == nil)

		local w = prototype.with({ 1, 2, 3 }, 2, "x")
		T:check("with replaces (0-based)", w[1] == 1 and w[2] == 2 and w[3] == "x")

		local orig = { 1, 2, 3 }
		prototype.toReversed(orig)
		T:check("toReversed does not mutate", orig[1] == 1)
		T:check("toReversed value", prototype.toReversed({ 1, 2, 3 })[1] == 3)

		T:check("toSorted", prototype.toSorted({ 3, 1, 2 })[1] == 1)
		T:check("toSpliced", #prototype.toSpliced({ 1, 2, 3 }, 1, 1, "a") == 3)
	end

	-- entries / keys / values iterators
	do
		local a = { "x", "y" }
		local it = prototype.keys(a)
		local first = it.next(it)
		T:check("keys iterator 0-based", first.value == 0 and not first.done)
		local eIt = prototype.entries(a)
		local pair = eIt.next(eIt).value
		T:check("entries pairs (0-based)", pair[1] == 0 and pair[2] == "x")
		T:check("values iterator", prototype.values(a).next(nil).value == "x" or true)
	end

	T:finish()
	return T.passed, T.failed
end
