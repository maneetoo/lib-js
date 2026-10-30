--!strict
-- Test-suite entry point: runs every `tests/*.luau` suite (except `_`-prefixed
-- internals) and exits non-zero on any failure.
-- Usage: lune run tests/run.luau [suite ...]   (no args = every suite)

local fs = require("@lune/fs")
local process = require("@lune/process")

local selected: { string } = {}
for _, arg in process.args do
	if arg ~= "" then
		table.insert(selected, arg)
	end
end

local suites: { string } = {}
if #selected > 0 then
	for _, name in selected do
		table.insert(suites, name)
	end
else
	for _, file in fs.readDir("tests") do
		if file:match("%.luau$") and not file:match("^_") and file ~= "run.luau" then
			table.insert(suites, file:sub(1, -6))
		end
	end
	table.sort(suites)
end

print("lib-js test suite")
print(("="):rep(60))

local failures: { string } = {}
local grandPassed, grandFailed = 0, 0

for _, suite in suites do
	print(`\n{suite}:`)
	local ok, err = pcall(function()
		local run = require(`./{suite}`)
		local passed, failed = run()
		grandPassed += passed
		grandFailed += failed
	end)
	if not ok then
		table.insert(failures, suite)
		print(`  SUITE ERROR: {err}`)
	end
end

print(("\n" .. ("="):rep(60)))
print(`total: {grandPassed} passed, {grandFailed} failed across {#suites} suites`)

if #failures > 0 then
	print(`failing suites: {table.concat(failures, ", ")}`)
	process.exit(1)
end
if grandFailed > 0 then
	process.exit(1)
end
