--!strict

--[=[
	@class encodeURI

	JavaScript's
	[`encodeURI()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURI):
	encode a complete URI.
]=]

const TypeError = require("../Error").TypeError
const shared = require("./__shared")

--[=[
	@within encodeURI
	@param uri string -- a complete URI
	@return string -- the URI with unsafe characters percent-encoded

	Encodes a complete URI: every byte not in the unreserved set
	(`A-Z a-z 0-9 - _ . ! ~ * ' ( )`) or the reserved set
	(`; / ? : @ & = + $ , #`) becomes `%XX`. The URI's structure characters
	survive untouched.
]=]
const function encodeURI(uri: string): string
	if type(uri) ~= "string" then
		error(TypeError.new("uri.encodeURI: argument must be a string"), 2)
	end
	return shared.encodeWith(uri, function(byte: number): boolean
		return shared.isUnreserved(byte) or shared.isReserved(byte)
	end)
end

return encodeURI
