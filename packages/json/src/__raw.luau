--!strict

--[=[
	@class __raw
	@private

	The "raw JSON" marker behind `JSON.rawJSON` and `JSON.isRawJSON`. A raw JSON
	object has no metatable (a null prototype), and its only own property is
	`rawJSON`, the text. Being a raw JSON object is a private slot in the
	JavaScript spec, so here it is a `WeakSet` of the objects this
	module made. A caller that copies the table's fields does not get the marker.
]=]

const WeakSet = require("../WeakSet")

export type RawJSON = {
	read rawJSON: string,
}

const registry = WeakSet.new()

--[=[
	@within __raw
	@private
	@param text string -- JSON text for one primitive, already validated
	@return RawJSON -- a frozen raw JSON object for `text`
]=]
const function create(text: string): RawJSON
	const raw = table.freeze({ rawJSON = text }) :: RawJSON
	registry:add(raw)
	return raw
end

--[=[
	@within __raw
	@private
	@param value unknown -- the value to test
	@return boolean -- `true` if `value` was made by `create`
]=]
const function isRaw(value: unknown): boolean
	return registry:has(value)
end

return table.freeze({
	create = create,
	isRaw = isRaw,
})
