--!strict

--[=[
	@class decodeURIComponent
	@within uri

	JavaScript's
	[`decodeURIComponent()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURIComponent):
	decode an encoded URI component.
]=]

const TypeError = require("../Error").TypeError
const shared = require("./__shared")

--[=[
	@within uri
	@param component string -- an encoded URI component
	@return string -- the component with every sequence decoded

	Decodes every percent-sequence, including those of reserved characters
	(`%2F` becomes `/`). Throws a `URIError` on malformed sequences.
]=]
const function decodeURIComponent(component: string): string
	if type(component) ~= "string" then
		error(TypeError.new("uri.decodeURIComponent: argument must be a string"), 2)
	end
	return shared.decodeWith(component, false)
end

return decodeURIComponent
