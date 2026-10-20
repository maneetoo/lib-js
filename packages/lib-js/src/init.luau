--!strict

const Array = require './Array'
const Boolean = require './Boolean'
const Error = require './Error'
const JSON = require './JSON'
const Map = require './Map'
const Math = require './Math'
const Number = require './Number'
const Object = require './Object'
const Promise = require './Promise'
const Set = require './Set'
const String = require './String'
const Symbol = require './Symbol'
const Timers = require './Timers'
const WeakMap = require './WeakMap'
const WeakRef = require './WeakRef'
const WeakSet = require './WeakSet'
const esTypes = require './ES17-Types'
const globalThis = require './globalThis'
const instanceof = require './instanceof'
const iterate = require './iterate'

export type Array<T> = esTypes.Array<T>
export type Table<K, V> = esTypes.Table<K, V>
export type Dictionary<V> = esTypes.Dictionary<V>
export type ReadonlyArray<T> = esTypes.ReadonlyArray<T>
export type ReadonlyTable<K, V> = esTypes.ReadonlyTable<K, V>
export type Nullable<T> = esTypes.Nullable<T>
export type Optional<T> = esTypes.Optional<T>
export type Entry2<K, V> = esTypes.Entry2<K, V>
export type Entry3<A, B, C> = esTypes.Entry3<A, B, C>
export type Thunk<T> = esTypes.Thunk<T>
export type Predicate<T> = esTypes.Predicate<T>
export type Comparator<T> = esTypes.Comparator<T>
export type Mapper<T, U> = esTypes.Mapper<T, U>
export type Reducer<T, U> = esTypes.Reducer<T, U>
export type Visitor<T> = esTypes.Visitor<T>
export type Thenable<T> = esTypes.Thenable<T>
export type Awaitable<T> = esTypes.Awaitable<T>
export type IteratorResult<T> = esTypes.IteratorResult<T>
export type Iterator<T> = esTypes.Iterator<T>

export type Map<K, V> = Map.Map<K, V>
export type MapPrototype = Map.MapPrototype
export type MapStatic = Map.MapStatic

export type Promise<T> = Promise.Promise<T>
export type PromiseThen<T> = Promise.PromiseThen<T>
export type PromiseFulfilledResult<T> = Promise.PromiseFulfilledResult<T>
export type PromiseRejectedResult = Promise.PromiseRejectedResult
export type PromiseSettledResult<T> = Promise.PromiseSettledResult<T>
export type PromiseWithResolvers<T> = Promise.PromiseWithResolvers<T>
export type PromisePrototype = Promise.PromisePrototype
export type PromiseStatic = Promise.PromiseStatic

export type Set<T> = Set.Set<T>
export type SetLike<T> = Set.SetLike<T>
export type SetPrototype = Set.SetPrototype
export type SetStatic = Set.SetStatic

export type Symbol = Symbol.Symbol

export type WeakMap<K, V> = WeakMap.WeakMap<K, V>

export type WeakRef<T> = WeakRef.WeakRef<T>
export type WeakRefPrototype = WeakRef.WeakRefPrototype
export type WeakRefStatic = WeakRef.WeakRefStatic

export type WeakSet<T> = WeakSet.WeakSet<T>
export type WeakSetPrototype = WeakSet.WeakSetPrototype
export type WeakSetStatic = WeakSet.WeakSetStatic

const lib = table.freeze {
	Array = Array,
	Boolean = Boolean,
	Error = Error,
	JSON = JSON,
	Map = Map,
	Math = Math,
	Number = Number,
	Object = Object,
	Promise = Promise,
	Set = Set,
	String = String,
	Symbol = Symbol,
	Timers = Timers,
	WeakMap = WeakMap,
	WeakRef = WeakRef,
	WeakSet = WeakSet,
	globalThis = globalThis,
	instanceof = instanceof,
	iterate = iterate,
}

return lib
