--!strict

--[=[
	@class __staticProps
	@private

	The numeric literals behind `Number`'s static properties, factored
	out into their own module so both `init` (which exposes them
	directly) and `isSafeInteger` (which needs `MAX_SAFE_INTEGER` for
	its own range check) share a single source of truth instead of
	duplicating magic numbers.
]=]

const math_huge = math.huge

return table.freeze({
	EPSILON = 2 ^ -52,
	MAX_SAFE_INTEGER = 2 ^ 53 - 1,
	MIN_SAFE_INTEGER = -(2 ^ 53 - 1),
	MAX_VALUE = 1.7976931348623157e+308,
	MIN_VALUE = 5e-324,
	NAN = 0 / 0,
	POSITIVE_INFINITY = math_huge,
	NEGATIVE_INFINITY = -math_huge,
})
