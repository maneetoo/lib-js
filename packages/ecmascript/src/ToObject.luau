--!strict

--[=[
	@class ToObject
	@private

	ECMA-262 §7.1.18 `ToObject(argument)`.
	https://tc39.es/ecma262/#sec-toobject

	Tables and userdata come back unchanged. Primitives come back unchanged too,
	because primitives are never boxed here. Functions are not objects here, so they
	come back unchanged as well.

	:::caution
	`nil` raises a `TypeError`, as JavaScript does for `undefined` and `null`. Luau's
	single `nil` stands for both, so the two are not told apart.
	:::
]=]

const TypeError = require "../Error" .TypeError

--[=[
	@within ToObject
	@param value any
	@return any
]=]
const function toObject(value: any): any
	if value == nil then
		error(TypeError.new("Cannot convert undefined or null to object"), 2)
	end
	return value
end

return ToObject
