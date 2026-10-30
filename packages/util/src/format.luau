--!strict

--[=[
	@class format
	@within util

	A Luau implementation of Node.js's
	[`util.format()`](https://nodejs.org/api/util.html#utilformatformat-args):
	a printf-style formatter with Node's exact specifier set and
	argument-overflow behaviour.

	```lua
	local format = require(path.to.util).format

	print(format("%s:%s", "foo", "bar", "baz")) -- foo:bar baz
	print(format("%s:%s", "foo"))               -- foo:%s
	print(format(1, 2, 3))                      -- 1 2 3
	```

	:::caution
	`%j` uses this library's `JSON.stringify`; a circular reference inside
	it becomes `"[Circular]"` (Node's marker) rather than throwing.
	:::

	:::caution
	`%c` (CSS, ignored by Node since v12.11.0) is accepted and skips its
	argument, as Node does. `%o`/`%O` both use this library's `inspect`
	(there are no non-enumerable properties or proxies in Luau to tell them
	apart).
	:::
]=]

const JSON = require("../JSON")
const inspect = require("./inspect")

const function stringifySimple(value: any): string
	const kind = type(value)
	if kind == "string" then
		return value
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
		return tostring(value)
	end
	if kind == "boolean" or kind == "nil" then
		return tostring(value)
	end
	if kind == "table" then
		-- Node renders a plain object argument with a shallow inspect.
		return inspect(value, { depth = 0, compact = true })
	end
	return tostring(value)
end

--[=[
	@within util
	@param format any -- the format string; when it contains no specifier, all arguments are joined with spaces
	@param ... any -- the values the specifiers consume
	@return string -- the formatted result

	Formats like Node's `util.format`:

	- `%s` — `String(value)` (tables via a depth-0 inspect, like Node)
	- `%d` — `Number(value)`; non-numeric strings give `NaN`
	- `%i` — `parseInt(value, 10)` truncation semantics
	- `%f` — `parseFloat(value)` semantics
	- `%j` — JSON, with circular references as `"[Circular]"`
	- `%o` / `%O` — `inspect(value)`
	- `%c` — ignored, its argument is skipped (as Node does)
	- `%%` — a literal `%`, consuming no argument
	- A specifier with no argument left stays as-is (`"foo:%s"`)
	- Extra arguments are appended, separated by spaces
	- A first argument with no specifiers joins everything with spaces
]=]
const function format(fmt: any, ...: any): string
	const args = table.pack(...)
	local argIndex = 0

	const function nextArg(): any
		argIndex += 1
		if argIndex > args.n then
			return nil
		end
		return args[argIndex]
	end

	local text
	if type(fmt) == "string" then
		text = fmt
	else
		-- Not a string: join everything with spaces, Node's rule.
		const pieces: { string } = {}
		for index = 0, args.n do
			pieces[index + 1] = if index == 0 then stringifySimple(fmt) else stringifySimple(args[index])
		end
		return table.concat(pieces, " ")
	end

	const out: { string }, length = {}, #text
	local count, index = 0, 1
	while index <= length do
		const char = text:sub(index, index)
		if char ~= "%" then
			count += 1
			out[count] = char
			index += 1
			continue
		end

		const specifier = text:sub(index + 1, index + 1)
		if specifier == "" then
			-- Trailing lone `%`: keep it.
			count += 1
			out[count] = "%"
			index += 1
			continue
		elseif specifier == "%" then
			count += 1
			out[count] = "%"
			index += 2
			continue
		end

		const value = nextArg()
		if value == nil and argIndex > args.n then
			-- Missing argument: the specifier stays as-is.
			count += 1
			out[count] = `%{specifier}`
			index += 2
			continue
		end

		local rendered
		if specifier == "s" then
			rendered = stringifySimple(value)
		elseif specifier == "d" then
			local number = tonumber(value)
			if number == nil then
				if type(value) == "boolean" then
					number = if value then 1 else 0
				else
					rendered = "NaN"
				end
			end
			if rendered == nil then
				-- Node's %d drops the fraction.
				rendered = tostring(math.floor(number :: number))
			end
		elseif specifier == "i" then
			const number = tonumber(tostring(value)) ~= nil and tonumber(tostring(value)) or tonumber(value)
			if number == nil then
				rendered = "NaN"
			else
				rendered = tostring(math.floor(number))
			end
		elseif specifier == "f" then
			const number = tonumber(tostring(value))
			if number == nil then
				rendered = "NaN"
			else
				rendered = tostring(number)
			end
		elseif specifier == "j" then
			const ok, encoded = pcall(function()
				return JSON.stringify(value)
			end)
			if ok then
				rendered = if encoded == nil then "undefined" else encoded
			else
				rendered = "[Circular]"
			end
		elseif specifier == "o" or specifier == "O" then
			rendered = inspect(value)
		elseif specifier == "c" then
			-- CSS: skipped entirely, consuming its argument.
			index += 2
			continue
		else
			-- Unknown specifier: `%` plus the character, verbatim, and the
			-- argument is pushed back (Node does not consume for unknowns).
			argIndex -= 1
			count += 1
			out[count] = `%{specifier}`
			index += 2
			continue
		end

		count += 1
		out[count] = rendered
		index += 2
	end

	-- Extra arguments, space-separated.
	if argIndex < args.n then
		const extra: { string } = {}
		for position = argIndex + 1, args.n do
			table.insert(extra, stringifySimple(args[position]))
		end
		const joined = table.concat(extra, " ")
		if #joined > 0 then
			count += 1
			out[count] = " " .. joined
		end
	end

	return table.concat(out)
end

return format
