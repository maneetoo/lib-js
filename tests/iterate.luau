--!strict
-- iterate: the shared iterable-draining helper.
-- Also: instanceof and globalThis (tiny single-function packages).

local loader = require("./_loader")
local T = require("./_init").new("iterate")

local iterate = loader.loadPackage("iterate") :: any
local Symbol = loader.loadPackage("Symbol") :: any

return function(): (number, number)
	-- nil: no-op
	do
		local count = 0
		iterate(nil, function()
			count += 1
		end)
		T:check("nil iterates nothing", count == 0)
	end

	-- array: elements 1..#t in order
	do
		local seen: { number } = {}
		iterate({ 10, 20, 30 }, function(value)
			table.insert(seen, value)
		end)
		T:check("array iterated in order", seen[1] == 10 and seen[3] == 30 and #seen == 3)
	end

	-- string: code points
	do
		local chars: { string } = {}
		iterate("abc", function(char)
			table.insert(chars, char)
		end)
		T:check("string iterates code points", table.concat(chars) == "abc")
		local wide: { string } = {}
		iterate("a😀b", function(char)
			table.insert(wide, char)
		end)
		T:check("multi-byte char is one step", #wide == 3 and wide[2] == "😀")
	end

	-- Symbol.iterator protocol
	do
		local counter = 0
		local iterable = setmetatable({}, {
			__index = function(_self, key)
				if key == Symbol.iterator then
					return function(_self2)
						local iterator = {}
						iterator.next = function(_self3)
							counter += 1
							return { value = counter, done = counter > 3 }
						end
						return iterator
					end
				end
				return nil
			end,
		})
		local sum = 0
		iterate(iterable, function(value)
			sum += value
		end)
		T:check("Symbol.iterator protocol drained", sum == 6)
	end

	-- non-iterable values throw
	do
		T:expectError("number not iterable", function()
			iterate(5, function() end)
		end)
		T:expectError("boolean not iterable", function()
			iterate(true, function() end)
		end)
	end

	T:finish()
	return T.passed, T.failed
end
