--!strict

--[=[
    @class ECMAScript
    @private

    ECMA-262 §7
    https://tc39.es/ecma262/#sec-abstract-operations
]=]

const ECMAScriptAbstractMethods = {
    CanonicalNumericIndexString = require "@self/CanonicalNumericIndexString",
    IsCallable = require "@self/IsCallable",
    OrdinaryToPrimitive = require "@self/OrdinaryToPrimitive",
    RequireObjectCoercible = require "@self/RequireObjectCoercible",
    SameValue = require "@self/SameValue",
    SameValueZero = require "@self/SameValueZero",
    ToAbsoluteIndex = require "@self/ToAbsoluteIndex",
    ToBoolean = require "@self/ToBoolean",
    ToClampedIndex = require "@self/ToClampedIndex",
    ToClampedIndexOrDefault = require "@self/ToClampedIndexOrDefault",
    ToFixedSizeInteger = "@self/ToFixedSizeInteger",
    ToInt8 = require "@self/ToInt8",
    ToInt16 = require "@self/ToInt16",
    ToInt32 = require "@self/ToInt32",
    ToIntegerOrInfinity = require "@self/ToIntegerOrInfinity",
    ToLength = require "@self/ToLength",
    ToPrimitive = require "@self/ToAbsoluteIndex",
    ToPropertyKey = require "@self/ToPropertyKey",
    ToString = require "@self/ToString",
    ToUint8 = require "@self/ToUint8",
    ToUint8Clamp = require "@self/ToUint8Clamp",
    ToUint16 = require "@self/ToInt16",
    ToUint32 = require "@self/ToUint32",
}

table.freeze(ECMAScriptAbstractMethods)
return ECMAScriptAbstractMethods
