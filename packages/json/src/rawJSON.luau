--!strict

--[=[
	@class rawJSON

	A Luau implementation of JavaScript's
	[`JSON.rawJSON()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/rawJSON).

	Creates a "raw JSON" object that holds one piece of JSON text. `stringify`
	writes that text as it is, so a value can be serialized in a form that
	`stringify` could not otherwise produce. The usual case is an integer too
	large for a double, such as `12345678901234567890`.
]=]

const String = require("../String")
const Symbol = require("../Symbol")
const SyntaxError = require("../Error").SyntaxError
const TypeError = require("../Error").TypeError
const parse = require("./parse")
const __raw = require("./__raw")

--[=[
	@within rawJSON
	@private
	True for the four whitespace characters JSON allows: tab, line feed, carriage return, space.
]=]
const function isWhitespace(byte: number?): boolean
	return byte == 9 or byte == 10 or byte == 13 or byte == 32
end

--[=[
	@within rawJSON
	@param text unknown -- the JSON text. Coerced with `ToString`. It must be valid JSON for one primitive value.
	@return RawJSON -- a frozen object with `rawJSON` set to `text`, and with a null prototype

	Throws a `SyntaxError` if `text` is not valid JSON. It also throws for an
	object or an array, for leading or trailing whitespace, and for an empty
	string. The text is kept exactly as given, so `"1.0"` stays `1.0`.

	:::note
	`rawJSON("null")` is a raw object for `null`. This library has no separate
	`null`, so it is not the same as `nil`. Inside an object, `stringify` writes
	it as `null`, and the property is kept.
	:::
]=]
const function rawJSON(text: unknown?): __raw.RawJSON
	if Symbol.isSymbol(text) then
		error(TypeError.new("Cannot convert a Symbol value to a string"), 2)
	end
	const source: string = String(text)
	if source == "" or isWhitespace(source:byte(1)) or isWhitespace(source:byte(#source)) then
		error(SyntaxError.new("JSON.rawJSON: text must be a JSON primitive with no surrounding whitespace"), 2)
	end
	-- `parse` rejects malformed text with a SyntaxError of its own. A table
	-- result means an object or an array, which raw JSON cannot hold.
	if type(parse(source)) == "table" then
		error(SyntaxError.new("JSON.rawJSON: text must be a JSON primitive, not an object or array"), 2)
	end
	return __raw.create(source)
end

return rawJSON
