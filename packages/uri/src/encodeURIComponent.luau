--!strict

--[=[
	@class encodeURIComponent

	JavaScript's
	[`encodeURIComponent()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent):
	encode a single URI component.
]=]

const TypeError = require("../Error").TypeError
const shared = require("./__shared")

--[=[
	@within encodeURIComponent
	@param component string -- a single URI component
	@return string -- the component with everything structural escaped

	Encodes a URI component: every byte not in the unreserved set
	(`A-Z a-z 0-9 - _ . ! ~ * ' ( )`) becomes `%XX`. Reserved characters
	(`? & = /` ...) are escaped too, so the result is safe to embed as one
	component of a larger URI.
]=]
const function encodeURIComponent(component: string): string
	if type(component) ~= "string" then
		error(TypeError.new("uri.encodeURIComponent: argument must be a string"), 2)
	end
	return shared.encodeWith(component, shared.isUnreserved)
end

return encodeURIComponent
