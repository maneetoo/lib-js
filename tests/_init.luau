--!strict
-- Shared test context: assertion helpers and a per-suite runner.
-- Usage: local T = require("./_init").new("Object"); T:check(...); T:finish()

export type Test = {
	name: string,
	check: (self: Test, description: string, condition: boolean) -> (),
	expectError: (self: Test, description: string, fn: () -> ()) -> (),
	finish: (self: Test) -> (),
	passed: number,
	failed: number,
}

local Test = {}
Test.__index = Test

function Test.new(name: string): Test
	return setmetatable({ name = name, passed = 0, failed = 0 }, Test) :: any
end

function Test:check(description: string, condition: boolean)
	if condition then
		self.passed += 1
	else
		self.failed += 1
		print(`  FAIL [{self.name}] {description}`)
	end
end

function Test:expectError(description: string, fn: () -> ())
	local ok = pcall(fn)
	self:check(description, not ok)
end

function Test:finish()
	local total = self.passed + self.failed
	if self.failed > 0 then
		error(`[{self.name}] {self.failed} of {total} checks failed`, 0)
	end
	print(`  [{self.name}] {self.passed}/{total} passed`)
end

return {
	new = Test.new,
}
