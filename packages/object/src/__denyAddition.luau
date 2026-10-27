--!strict

--[=[
	@class __denyAddition
	@private

	The `__newindex` handler installed by `preventExtensions`. Not part of the public API.

	Luau only calls `__newindex` when the key is absent from the table, so it
	fires exactly for "adding a property" and never for changing or removing an
	existing one — the same line `Object.preventExtensions` draws in JavaScript.

	`isExtensible` recognises a non-extensible table by this function's
	identity, so it must stay one shared function and must never be wrapped or
	copied.

	:::note
	Assigning `nil` to an absent key is allowed and does nothing. In Luau that
	write is a no-op "delete", not the creation of a property holding
	`undefined`, so rejecting it would only break ordinary `t[key] = nil`
	clean-up code.
	:::
]=]

const function denyAddition(_object: any, key: any, value: any): ()
	if value == nil then
		return
	end
	error(`attempt to add property '{tostring(key)}' to a non-extensible object`, 2)
end

return denyAddition
