--!strict

--[=[
    @class ECMAScript
    @private

    ECMA-262 §7
    https://tc39.es/ecma262/#sec-abstract-operations
]=]

const ECMAScriptAbstractMethods = {
    IsCallable = require "@self/IsCallable",
    RequireObjectCoercible = require "@self/RequireObjectCoercible",
    ToBoolean = require "@self/ToBoolean",
    ToClampedIndex = require "@self/ToClampedIndex",
    ToClampedIndexOrDefault = require "@self/ToClampedIndexOrDefault",
    ToFixedSizeInteger = "@self/ToFixedSizeInteger",
    ToInt8 = require "@self/ToInt8",
    ToInt16 = require "@self/ToInt16",
    ToInt32 = require "@self/ToInt32",
    ToIntegerOrInfinity = require "@self/ToIntegerOrInfinity",
    ToLength = require "@self/ToLength",
    ToString = require "@self/ToString",
    ToUint8 = require "@self/ToUint8",
    ToUint16 = require "@self/ToInt16",
    ToUint32 = require "@self/ToUint32",
}

table.freeze(ECMAScriptAbstractMethods)
return ECMAScriptAbstractMethods
