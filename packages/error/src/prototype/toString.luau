--!strict

--[=[
	@class toString

	A Luau implementation of JavaScript's
	[`Error.prototype.toString()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error/toString).

	Returns `"<name>: <message>"`. An empty `name` yields only the message,
	and an empty `message` yields only the name.

	:::note
	This module exports a factory, `makeToString(throwTypeError)`, not the
	method itself. The factory needs a `TypeError` thrower, which
	`Error/__hierarchy.luau` supplies. See that module for why.
	:::
]=]

const String = require("../../String")
const Symbol = require("../../Symbol")

--[=[
	@within toString
	@param throwTypeError (message: string) -> () -- raises a `TypeError` with `message`
	@return (self: any) -> string -- the `toString` method

	The returned method throws a `TypeError` through `throwTypeError` when
	its receiver is not an object, as the spec requires. It also throws when
	`name` or `message` is a `Symbol`, because `ToString` rejects symbols.
]=]
const function toString(throwTypeError: (string) -> ()): (any) -> string
	return function(self: any): string
		const selfType: string = type(self)
		if not (selfType == "table" or selfType == "userdata") then
			throwTypeError("Error.prototype.toString called on a non-object")
		end

		const nameValue = self["name"]
		if Symbol.isSymbol(nameValue) then
			throwTypeError("Cannot convert a Symbol value to a string")
		end
		const messageValue = self["message"]
		if Symbol.isSymbol(messageValue) then
			throwTypeError("Cannot convert a Symbol value to a string")
		end
		const name: string = if nameValue == nil then "Error" else String(nameValue)
		const message: string = if messageValue == nil then "" else String(messageValue)

		if name == "" then
			return message
		end
		if message == "" then
			return name
		end
		return name .. ": " .. message
	end
end

return toString
