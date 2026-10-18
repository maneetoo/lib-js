--!strict

--[=[
	@class globalThis
	@within globalThis

	The global object, as JavaScript's
	[`globalThis`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/globalThis).
	In Luau this is the global table `_G`.

	:::caution
	This is the live global table, not a copy, and it is not frozen. A write
	through it changes the global scope for the whole program. The table is not
	given a `globalThis` field. Set `_G.globalThis = _G` yourself if you need one.
	:::
]=]

return _G
