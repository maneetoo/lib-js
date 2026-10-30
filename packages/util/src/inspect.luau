--!strict

--[=[
	@class inspect

	A Luau implementation of Node.js's
	[`util.inspect()`](https://nodejs.org/api/util.html#utilinspectobject-options):
	a debugging string for any value, with Node's default style.

	```lua
	local inspect = require(path.to.util).inspect

	print(inspect({ a = 1, list = { 1, 2, 3 } }))
	-- { a: 1, list: [ 1, 2, 3 ] }
	```

	:::caution
	A structural port of Node's *style*, not its whole feature set: no
	`colors`, `showProxy`, `getters`, `numericSeparator` (there are no
	colors, proxies or getters in Luau), and no `Symbol.for('nodejs.util.inspect.custom')`
	hook. The options that shape output here are `depth`, `breakLength`,
	`compact`, `maxArrayLength`, `maxStringLength`, and `sorted`.
	:::

	:::caution
	Luau tables are all "plain": there is no class-instance distinction, so
	every table renders as `{ ... }` (or `[ ... ]` when array-like), and a
	metatable-based class tag is not shown. This library's `Map` and `Set`
	instances are recognized and rendered Node-style (`Map(2) { 'a' => 1 }`,
	`Set(3) { 1, 2, 3 }`).
	:::
]=]

const Map = require("../Map")
const Set = require("../Set")
const Symbol = require("../Symbol")

--[=[
	@within inspect
	@type InspectOptions = { depth: number?, breakLength: number?, compact: (boolean | number)?, maxArrayLength: number?, maxStringLength: number?, sorted: boolean? }

	Options for `inspect`. All optional; the defaults are Node's: `depth`
	2, `breakLength` 80, `compact` 3, `maxArrayLength` 100,
	`maxStringLength` 10000, `sorted` false. `depth` accepts `math.huge`
	(Node's `Infinity`) for unlimited recursion.
]=]
export type InspectOptions = {
	depth: number?,
	breakLength: number?,
	compact: (boolean | number)?,
	maxArrayLength: number?,
	maxStringLength: number?,
	sorted: boolean?,
}

type ResolvedOptions = {
	depth: number,
	breakLength: number,
	compact: boolean,
	maxArrayLength: number,
	maxStringLength: number,
	sorted: boolean,
}

const DEFAULTS: ResolvedOptions = {
	depth = 2,
	breakLength = 80,
	-- Node's default is `compact: 3`: compact single-line output whenever
	-- the result fits breakLength.
	compact = true,
	maxArrayLength = 100,
	maxStringLength = 10000,
	sorted = false,
}

-- A key needing quotes: not a valid Luau identifier (approximating Node's
-- isIdentifier check for the keys this library can have).
const IDENTIFIER_PATTERN = "^[%a_][%w_]*$"

const function resolveOptions(options: InspectOptions?): ResolvedOptions
	if options == nil then
		return DEFAULTS
	end
	-- Compact unless explicitly disabled: Node's default is `compact: 3`.
	const compact = options.compact ~= false
	return {
		depth = if options.depth == nil then DEFAULTS.depth else options.depth,
		breakLength = if options.breakLength == nil then DEFAULTS.breakLength else options.breakLength,
		compact = compact,
		maxArrayLength = if options.maxArrayLength == nil then DEFAULTS.maxArrayLength else options.maxArrayLength,
		maxStringLength = if options.maxStringLength == nil then DEFAULTS.maxStringLength else options.maxStringLength,
		sorted = options.sorted == true,
	}
end

const function quoteString(text: string, maxLength: number): string
	const escaped = (
		text:gsub("[%c\\']", function(char: string): string
			if char == "\\" then
				return "\\\\"
			elseif char == "'" then
				return "\\'"
			elseif char == "\n" then
				return "\\n"
			elseif char == "\t" then
				return "\\t"
			elseif char == "\r" then
				return "\\r"
			end
			return `\\{string.byte(char)}`
		end)
	) :: string
	if #escaped > maxLength then
		return `'{escaped:sub(1, maxLength)}…'`
	end
	return `'{escaped}'`
end

const function formatKey(key: any, options: ResolvedOptions): string
	if type(key) == "string" then
		if key:match(IDENTIFIER_PATTERN) ~= nil then
			return key
		end
		return quoteString(key, options.maxStringLength)
	end
	if Symbol.isSymbol(key) then
		return `[{tostring(key)}]`
	end
	return `[{tostring(key)}]`
end

const function isLibraryInstance(value: any, classTable: any, methodName: string): boolean
	if type(value) ~= "table" then
		return false
	end
	const method = value[methodName]
	return type(method) == "function" and method == (classTable.prototype :: any)[methodName]
end

const function collectEntries(tbl: any, sorted: boolean): { { any } }
	const entries: { { any } } = {}
	local count = 0

	const function insert(key: any, value: any)
		count += 1
		entries[count] = { key, value }
	end

	if #tbl > 0 then
		for index = 1, #tbl do
			insert(index - 1, tbl[index])
		end
		for key, value in next, tbl do
			if type(key) ~= "number" then
				insert(key, value)
			end
		end
	else
		const keys: { any } = {}
		for key in next, tbl do
			table.insert(keys, key)
		end
		if sorted then
			table.sort(keys, function(a, b)
				return tostring(a) < tostring(b)
			end)
		end
		for _, key in keys do
			insert(key, tbl[key])
		end
	end
	return entries
end

-- The renderers call each other (tables contain Maps and Sets, Maps and
-- Sets contain tables), so they are forward-declared.
local renderMap: (tbl: any, depth: number, options: ResolvedOptions, seen: { [any]: number }) -> string
local renderSet: (tbl: any, depth: number, options: ResolvedOptions, seen: { [any]: number }) -> string
local renderTable: (tbl: any, depth: number, options: ResolvedOptions, seen: { [any]: number }) -> string

--[=[
	@within inspect
	@private
	Formats one value at `depth` remaining. `seen` maps visited tables to
	their reference index for circular markers.
]=]
const function render(value: any, depth: number, options: ResolvedOptions, seen: { [any]: number }): string
	const kind = type(value)
	if kind == "string" then
		return quoteString(value, options.maxStringLength)
	end
	if kind == "number" then
		if value ~= value then
			return "NaN"
		end
		if value == math.huge then
			return "Infinity"
		end
		if value == -math.huge then
			return "-Infinity"
		end
		if value == 0 and 1 / value < 0 then
			return "-0"
		end
		return tostring(value)
	end
	if kind == "boolean" then
		return tostring(value)
	end
	if kind == "nil" then
		return "nil"
	end
	if kind == "function" then
		return `[Function{(debug.info(value, "n") ~= nil and debug.info(value, "n") ~= "" and ": " .. debug.info(
			value,
			"n"
		)) or ""}]`
	end
	if kind == "thread" then
		return `[Thread]`
	end
	if kind ~= "table" then
		return tostring(value)
	end

	const tbl = value :: any
	if Symbol.isSymbol(tbl) then
		return tostring(tbl)
	end

	const ref = seen[tbl]
	if ref ~= nil then
		return `[Circular *{ref}]`
	end
	if depth < 0 then
		-- Depth exceeded: Node's placeholder for a nested object.
		if isLibraryInstance(tbl, Map, "entries") then
			return "[Map]"
		end
		if isLibraryInstance(tbl, Set, "add") then
			return "[Set]"
		end
		if #tbl > 0 then
			return "[Array]"
		end
		return "[Object]"
	end
	seen[tbl] = #seen + 1

	local result
	if isLibraryInstance(tbl, Map, "entries") then
		result = renderMap(tbl, depth, options, seen)
	elseif isLibraryInstance(tbl, Set, "add") then
		result = renderSet(tbl, depth, options, seen)
	else
		result = renderTable(tbl, depth, options, seen)
	end

	seen[tbl] = nil
	return result
end

function renderMap(tbl: any, depth: number, options: ResolvedOptions, seen: { [any]: number }): string
	const entries: { { any } } = {}
	local count = 0
	const entryIterator = tbl.entries(tbl)
	local step = entryIterator.next(entryIterator)
	while not step.done do
		local pair = step.value
		if count >= options.maxArrayLength then
			break
		end
		count += 1
		entries[count] = `{render(pair[1], depth - 1, options, seen)} => {render(pair[2], depth - 1, options, seen)}`
		step = entryIterator.next(entryIterator)
	end
	const suffix = if count < tbl.size then ", … " .. tostring(tbl.size - count) .. " more item(s)" else ""
	if count == 0 then
		return "Map(0) {}"
	end
	const body = table.concat(entries, ", ")
	const single = "Map(" .. tostring(tbl.size) .. ") { " .. body .. suffix .. " }"
	if options.compact and #single <= options.breakLength then
		return single
	end
	const lines: { string } = {}
	for index, entry in entries do
		lines[index] = `  {entry}`
	end
	return "Map("
		.. tbl.size
		.. ") {"
		.. tostring(string.char(10))
		.. table.concat(lines, "," .. string.char(10))
		.. suffix
		.. string.char(10)
		.. "}"
end

function renderSet(tbl: any, depth: number, options: ResolvedOptions, seen: { [any]: number }): string
	const members: { string } = {}
	local count = 0
	const valueIterator = tbl.values(tbl)
	local step = valueIterator.next(valueIterator)
	while not step.done do
		if count >= options.maxArrayLength then
			break
		end
		count += 1
		members[count] = render(step.value, depth - 1, options, seen)
		step = valueIterator.next(valueIterator)
	end
	const suffix = if count < tbl.size then ", … " .. tostring(tbl.size - count) .. " more item(s)" else ""
	if count == 0 then
		return "Set(0) {}"
	end
	const body = table.concat(members, ", ")
	const single = "Set(" .. tostring(tbl.size) .. ") { " .. body .. suffix .. " }"
	if options.compact and #single <= options.breakLength then
		return single
	end
	const lines: { string } = {}
	for index, member in members do
		lines[index] = `  {member}`
	end
	return "Set("
		.. tbl.size
		.. ") {"
		.. tostring(string.char(10))
		.. table.concat(lines, "," .. string.char(10))
		.. suffix
		.. string.char(10)
		.. "}"
end

function renderTable(tbl: any, depth: number, options: ResolvedOptions, seen: { [any]: number }): string
	const entries = collectEntries(tbl, options.sorted)
	const isArray = #tbl > 0

	if #entries > options.maxArrayLength then
		-- Truncate the rendering, Node's "… N more item(s)" marker.
		const shown: { string } = {}
		for index = 1, options.maxArrayLength do
			shown[index] = render(entries[index][2], depth - 1, options, seen)
		end
		const extra = `… {#entries - options.maxArrayLength} more item(s)`
		if isArray then
			return `[ {table.concat(shown, ", ")}, {extra} ]`
		end
		const joined = table.concat(shown, ", ")
		return "{" .. joined .. ", " .. extra .. "}"
	end

	const parts: { string } = {}
	for index, entry in entries do
		local key, value = entry[1], entry[2]
		if isArray and type(key) == "number" then
			parts[index] = render(value, depth - 1, options, seen)
		else
			-- A keyed entry inside an array-like table renders with its key,
			-- Node's mixed style: [ 1, 2, x: 3 ].
			parts[index] = `{formatKey(key, options)}: {render(value, depth - 1, options, seen)}`
		end
	end

	if #parts == 0 then
		return if isArray then "[]" else "{}"
	end

	const opener, closer = if isArray then "[" else "{", if isArray then "]" else "}"
	const single = `{opener} {table.concat(parts, ", ")} {closer}`
	if options.compact and #single <= options.breakLength then
		return single
	end
	const lines: { string } = {}
	for index, part in parts do
		lines[index] = `  {part}`
	end
	return `{opener}\n{table.concat(lines, ",\n")}\n{closer}`
end

--[=[
	@within inspect
	@param value any -- the value to describe
	@param options InspectOptions? -- output-shaping options
	@return string -- the inspection string

	Returns a Node-style debugging string for `value`. See the class
	documentation for the supported subset of options and the documented
	divergences.
]=]
const function inspect(value: any, options: InspectOptions?): string
	return render(value, resolveOptions(options).depth, resolveOptions(options), {})
end

return inspect
