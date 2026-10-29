--!strict

--[=[
	@class uri

	Luau implementations of JavaScript's global URI functions:
	[`encodeURI()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURI),
	[`encodeURIComponent()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent),
	[`decodeURI()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURI)
	and
	[`decodeURIComponent()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURIComponent).

	All four share one UTF-8 percent-encoding algorithm and differ only in
	which characters they leave unescaped:

	- `encodeURI` keeps the unreserved set plus the reserved set
	  (`; / ? : @ & = + $ , #`), so a whole URI's structure survives.
	- `encodeURIComponent` keeps only the unreserved set
	  (`A-Z a-z 0-9 - _ . ! ~ * ' ( )`), escaping everything a component must
	  not carry.
	- `decodeURI` decodes percent-sequences except those that decode to
	  reserved characters.
	- `decodeURIComponent` decodes every percent-sequence.

	```lua
	local uri = require(path.to.uri)

	print(uri.encodeURI("https://x/a b?q=é"))      -- https://x/a%20b?q=%C3%A9
	print(uri.encodeURIComponent("Jack & Jill"))   -- Jack%20%26%20Jill
	print(uri.decodeURIComponent("Jack%20%26%20Jill")) -- Jack & Jill
	```

	:::caution
	JavaScript operates on UTF-16 code units and throws a `URIError` when
	encoding a lone surrogate. Luau strings are byte sequences that cannot
	contain invalid UTF-8 by construction, so that error cannot happen here;
	an invalid byte is percent-encoded as-is.
	:::
]=]

return table.freeze({
	encodeURI = require("@self/encodeURI"),
	encodeURIComponent = require("@self/encodeURIComponent"),
	decodeURI = require("@self/decodeURI"),
	decodeURIComponent = require("@self/decodeURIComponent"),
})
