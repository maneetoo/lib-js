--!strict

--[=[
	@class __shared
	@private

	Internal helpers shared by the property-definition modules of `Object`
	(`defineProperty`, `defineProperties`, `getOwnPropertyDescriptor`,
	`getOwnPropertyDescriptors`). Not part of the public API.

	:::note
	Keep helpers small. Logic used by a single method lives in that method's file.
	:::
]=]

const is = require("./is")
const isExtensible = require("./isExtensible")

--[=[
	@within Object
	@type PropertyDescriptor = { value: any?, writable: boolean?, enumerable: boolean?, configurable: boolean? }

	The record `defineProperty`/`defineProperties` accept and
	`getOwnPropertyDescriptor`/`getOwnPropertyDescriptors` return.

	:::caution
	Only *data* descriptors exist. Accessor properties (`get`/`set`) are not
	supported, because Luau has no per-key getters or setters short of
	replacing the table's `__index`, which this library reserves for the
	prototype chain (`getPrototypeOf`, `setPrototypeOf`).
	:::

	:::caution
	Luau tables have no per-key attributes, so `writable`, `enumerable` and
	`configurable` cannot be stored. `defineProperty` accepts and ignores them;
	`getOwnPropertyDescriptor` reports what is actually true: `enumerable` is
	always `true`, and `writable`/`configurable` are `true` unless the whole
	table is frozen.
	:::
]=]
export type PropertyDescriptor = {
	value: any?,
	writable: boolean?,
	enumerable: boolean?,
	configurable: boolean?,
}

-- Builds the descriptor reported for an existing own key. `mutable` is
-- `false` only for a frozen table, the one case where Luau restricts
-- changing or removing a key.
const function describe(value: any, mutable: boolean): PropertyDescriptor
	return { value = value, writable = mutable, enumerable = true, configurable = mutable }
end

-- Rejects descriptors this library cannot honour. Errors are raised at level
-- 3 so they blame the caller of the public function that called this one.
const function validate(caller: string, key: any, descriptor: any): ()
	if type(descriptor) ~= "table" then
		error(`{caller}: property description for '{tostring(key)}' must be a table, got {typeof(descriptor)}`, 3)
	end
	if descriptor.get ~= nil or descriptor.set ~= nil then
		error(`{caller}: accessor properties (get/set) are not supported, use a 'value' descriptor`, 3)
	end
end

-- Applies an already validated descriptor. Mirrors JavaScript's
-- [[DefineOwnProperty]]: it writes the raw slot, so `__newindex` is never
-- consulted, and the frozen / non-extensible rules are enforced by hand
-- because `rawset` would ignore the second one entirely.
const function define(caller: string, object: any, key: any, descriptor: PropertyDescriptor): ()
	if key == nil then
		error(`{caller}: property key must not be nil`, 3)
	end

	const value = descriptor.value
	const existing = rawget(object, key)

	if table.isfrozen(object) then
		-- As in JavaScript, redefining a frozen property with the very same
		-- value is accepted; anything else is a TypeError there.
		if existing == nil then
			error(`{caller}: cannot define property '{tostring(key)}', the object is frozen`, 3)
		end
		if value ~= nil and not is(existing, value) then
			error(`{caller}: cannot redefine property '{tostring(key)}' of a frozen object`, 3)
		end
		return
	end

	if existing == nil and not isExtensible(object) then
		error(`{caller}: cannot define property '{tostring(key)}', the object is not extensible`, 3)
	end

	-- A descriptor without `value` leaves an existing value alone, and cannot
	-- create a key holding `nil` (that would be no key at all).
	if value ~= nil then
		rawset(object, key, value)
	end
end

return table.freeze({
	describe = describe,
	validate = validate,
	define = define,
})
