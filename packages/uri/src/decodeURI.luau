--!strict

--[=[
	@class decodeURI
	@within uri

	JavaScript's
	[`decodeURI()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURI):
	decode an encoded URI.
]=]

const TypeError = require("../Error").TypeError
const shared = require("./__shared")

--[=[
	@within uri
	@param uri string -- an encoded URI
	@return string -- the URI with decodable sequences decoded

	Decodes percent-sequences that do not stand for reserved characters:
	`%20` becomes a space, but `%2F` stays `%2F`, so an encoded `/` cannot
	quietly change the URI's structure. Throws a `URIError` on malformed
	sequences (bad hex, incomplete `%XX`, invalid UTF-8).
]=]
const function decodeURI(uri: string): string
	if type(uri) ~= "string" then
		error(TypeError.new("uri.decodeURI: argument must be a string"), 2)
	end
	return shared.decodeWith(uri, true)
end

return decodeURI
