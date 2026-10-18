--!strict

--[=[
	@class instanceof

	A Luau implementation of JavaScript's [`instanceof`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/instanceof)
	operator.

	Checks whether a value's prototype chain contains a given class's
	prototype — the same walk JavaScript performs for
	`value instanceof Constructor` (the `OrdinaryHasInstance` abstract
	operation).

	:::note
	Luau has no `instanceof` operator, and no built-in notion of
	"constructor" at all — classes are purely a convention built on
	metatables. Two conventions are understood here:

	- **Class-as-prototype** (the common Luau pattern): the class table
	  itself is installed as `__index` on instances, and inheritance is
	  expressed by one class's own `__index` pointing at its base
	  class. Passing that class table directly as `constructor` works
	  as-is — this is used automatically whenever `constructor` has no
	  `prototype` field at all, since that's not a concept JS
	  constructors can lack but Luau "classes" routinely do.
	- **Constructor-with-`.prototype`** (the JS-shaped pattern):
	  `constructor` is a table exposing a `prototype` field, and *that*
	  table is what actually gets installed as `__index` on instances —
	  mirroring `Constructor.prototype` in JS.
	:::
]=]

const esTypes = require "./ES17-Types"

--[=[
	Returns the next link in `current`'s `__index`-based prototype chain
	(a table), or `nil` if the chain ends here — no metatable, a
	protected metatable, no `__index`, or a non-table `__index` (a
	computed-property getter function, which is never itself a
	prototype object to compare against).

	Kept as its own tiny function so the tortoise/hare walk below can
	call it identically for both pointers without duplicating the
	metatable/`__index` logic three times inline.
]=]
const function step(current: any): any?
	const metatable = getmetatable(current)
	if type(metatable) ~= "table" then
		return nil
	end

	-- `rawget` guards against a metatable whose own metatable defines a
	-- custom `__index`, which could otherwise make `metatable.__index`
	-- resolve to something other than the metatable's own, real entry.
	const index = rawget(metatable :: any, "__index")
	if type(index) ~= "table" then
		return nil
	end

	return index
end

--[=[
	@within instanceof
	@param value any -- the value to test
	@param constructor esTypes.Table<any, any> -- the class/constructor to test against
	@return boolean -- `true` if `value`'s prototype chain contains `constructor`'s prototype

	Walks `value`'s chain of `__index` links — `getmetatable(value).__index`,
	then `getmetatable(that).__index`, and so on — looking for the
	prototype `constructor` represents. Stops and returns `false` as
	soon as the chain runs out (no metatable, a protected metatable, or
	no `__index`) without finding it.

	:::note
	`value` being the prototype *itself* does not count as an instance
	of it — `instanceof(MyClass, MyClass)` is `false`, matching how a
	class's own prototype object is never considered an instance of
	itself in JS either.
	:::

	:::note
	Non-table, non-`userdata` values (numbers, strings, booleans, `nil`)
	always report `false` rather than erroring, since such values can
	never carry a metatable-based prototype chain — mirroring how
	`5 instanceof Number` is `false` in JS: primitives are never
	instances of anything. Matching the real `OrdinaryHasInstance`
	algorithm's own step order, this check happens *before*
	`constructor.prototype` is ever read or validated — so testing a
	primitive `value` never errors, even if `constructor.prototype`
	happens to be malformed.
	:::

	:::caution
	Luau deliberately omits `debug.setmetatable` — present in reference
	Lua as the only way to attach a metatable to a non-table value
	(function, number, boolean, `thread`) — as a sandboxing/security
	measure, and the public `setmetatable`/`getmetatable` pair only ever
	operates on tables. Since there is consequently no supported way to
	give a Luau function a metatable at all, a function can never carry
	an `__index` link and so can never participate in a prototype chain:
	`instanceof(someFunction, Object)` is always `false`. This is a
	genuine divergence from JavaScript, where functions *are* objects
	and routinely are instances of `Function`/`Object` — but it stems
	from Luau's stdlib/sandboxing design, not from some inherent
	inability of the function type to hold a metatable.
	:::

	:::caution
	Only a table `__index` is ever treated as a link in the prototype
	chain. If some `__index` along the way is a function (the "computed
	property" getter pattern) rather than a table, that is not a
	prototype object to compare against — traversal simply stops there,
	exactly as this library's `Object.prototype.isPrototypeOf` behaves.
	:::

	:::caution
	`constructor` itself must be a table — passing a number, string,
	boolean, function, or `nil` raises an error, mirroring the
	`TypeError: Right-hand side of 'instanceof' is not callable` that
	JavaScript throws for a non-constructor right-hand side.
	:::

	:::caution
	`constructor.prototype`, when present, must be a table. A *missing*
	`prototype` field is treated as an intentional use of the
	class-as-prototype convention (see the class-level docs) and falls
	back to using `constructor` itself — but a `prototype` field that
	*is* present and holds something other than a table is almost
	certainly a mistake, not a deliberate convention, and raises an
	error instead of being silently ignored. This mirrors the real
	`OrdinaryHasInstance` algorithm, which throws a `TypeError` the
	moment `Constructor.prototype` resolves to a non-object.
	:::

	:::caution
	Every link in the chain is compared, and every `__index` field is
	read, using `rawequal`/`rawget` rather than `==`/`.`. This is
	deliberate: a class or prototype table could carry its own `__eq`
	metamethod (for unrelated value-equality purposes) or its own
	`__index` (for computed properties), either of which would silently
	corrupt a plain `==`/`.`-based walk. The prototype chain must be
	walked by reference identity alone, exactly as JS's internal
	`[[Prototype]]` chain is (`SameValue`, not `==`-style comparison).
	:::

	:::caution
	If a metatable in the chain is protected with `__metatable` set to
	some *other table* (as opposed to a string, which is far more
	common), `getmetatable` returns that protection value, and there is
	no sanctioned way to tell it apart from a real metatable. In that
	rare case, the walk silently treats the protection value as if it
	were the real metatable and very likely fails to find a match,
	rather than raising an error — the same limitation documented on
	this library's `Object.getPrototypeOf`.
	:::
]=]
const function instanceof(value: any, constructor: esTypes.Table<any, any>): boolean
	if type(constructor) ~= "table" then
		error("instanceof: right-hand side is not a class/constructor table", 2)
	end

	-- Primitives (and functions — see the class-level caution) can never
	-- have a metatable-based prototype chain, so they can never be
	-- "instances" of anything. This check deliberately comes before
	-- `constructor.prototype` is read/validated below, matching the
	-- real OrdinaryHasInstance algorithm's step order: testing a
	-- primitive never errors, even against a malformed `constructor`.
	if type(value) ~= "table" and type(value) ~= "userdata" then
		return false
	end

	-- `rawget`, not plain indexing: a metatable-driven computed
	-- `prototype` property on `constructor` must not be able to
	-- influence which convention gets picked below.
	const declaredPrototype = rawget(constructor :: any, "prototype")
	local prototype: any

	if declaredPrototype == nil then
		-- No `.prototype` field at all: not a mistake, just the
		-- class-as-prototype convention, where the class table is its
		-- own prototype object.
		prototype = constructor
	elseif type(declaredPrototype) == "table" then
		prototype = declaredPrototype
	else
		-- A `.prototype` field exists but isn't a table: this can't be
		-- the class-as-prototype convention (that one simply omits the
		-- field), so it's almost certainly a mistake. Fail loudly,
		-- mirroring the TypeError real JS throws for exactly this case.
		error(`instanceof: constructor.prototype must be a table, got {type(declaredPrototype)}`, 2)
	end

	-- Floyd's cycle-detection ("tortoise and hare") walk: `slow` moves
	-- one link per iteration, `fast` moves two. This guards against a
	-- cyclic `__index` chain (e.g. two classes mistakenly pointing at
	-- each other) in O(1) extra space — unlike a hash-set of visited
	-- tables, it needs no allocation at all, which matters since this
	-- function may sit on a hot path (e.g. type-checking inside a
	-- loop).
	local slow: any, fast: any = value, value

	while true do
		slow = step(slow)
		if slow == nil then
			return false
		end
		if rawequal(slow, prototype) then
			return true
		end

		fast = step(fast)
		if fast == nil then
			return false
		end
		if rawequal(fast, prototype) then
			return true
		end

		fast = step(fast)
		if fast == nil then
			return false
		end
		if rawequal(fast, prototype) then
			return true
		end

		-- `fast` has gone twice as far as `slow` this round; if they've
		-- landed on the exact same table, the chain loops and will
		-- never reach `prototype` no matter how much further it's
		-- walked.
		if rawequal(slow, fast) then
			return false
		end
	end
end

return instanceof
