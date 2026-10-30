--!strict

--[=[
	@class CanonicalNumericIndexString
	@within AbstractOperations

	ECMA-262 §7.1.21 `CanonicalNumericIndexString(argument)`.
	https://tc39.es/ecma262/#sec-canonicalnumericindexstring

	Returns the number a string stands for, if converting that number back to a
	string gives the original string exactly. Otherwise returns nil.
	`"-0"` gives negative zero. Typed arrays use this to decide whether a
	string key is a numeric index.
]=]

const Number = require("../Number")
const ToString = require("./ToString")

--[=[
	@within CanonicalNumericIndexString
	@param argument string
	@return number? -- the number, or nil if the string is not canonical numeric

	`CanonicalNumericIndexString("1.5")` gives `1.5`. `CanonicalNumericIndexString("01")` gives nil.
	`CanonicalNumericIndexString("-0")` gives `-0`.
]=]
const function CanonicalNumericIndexString(argument: string): number?
	if argument == "-0" then
		return -0.0
	end
	const n = Number(argument)
	if ToString(n) == argument then
		return n
	end
	return nil
end

return CanonicalNumericIndexString
