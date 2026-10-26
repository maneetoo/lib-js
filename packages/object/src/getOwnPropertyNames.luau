--!strict

--[=[
	@class getOwnPropertyNames

	A Luau implementation of JavaScript's [`Object.getOwnPropertyNames()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/getOwnPropertyNames).

	Returns an array of a table's own keys.
]=]

const esTypes = require("../ES17-Types")

--[=[
	@within getOwnPropertyNames
	@param object { [K]: V } -- the table to list keys of
	@return { K } -- an array containing every key found in `object`

	:::note
	In JavaScript, `Object.keys` only returns *enumerable* string keys,
	while `Object.getOwnPropertyNames` additionally includes
	non-enumerable ones. Luau tables have no such distinction — every
	key stored in a table is equally "enumerable" — so this is the very
	same function as this library's `keys` (re-exported, not copied, so
	the two can never drift apart and there is zero extra call
	overhead). It exists purely for API parity with JavaScript's
	`Object`.
	:::
    
	:::note
	As with `keys`/`values`/`entries`, the order of the returned names
	follows Luau's unspecified iteration order and should not be relied
	upon.
	:::
]=]
const getOwnPropertyNames: <K, V>(object: esTypes.Table<K, V>) -> esTypes.Array<K> = require("./keys")

return getOwnPropertyNames
