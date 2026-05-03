import cpp
import lib.guard_checker
import lib.patterns
import lib.types

string witnessFamily(InnerPointerTakingExpr innerPointerTaking) {
  if isStringInnerPointerTaking(innerPointerTaking)
  then result = "string"
  else if isArrayInnerPointerTaking(innerPointerTaking)
  then result = "array"
  else
    if exists(InnerPointerTakingMacroInvocation mi |
      innerPointerTaking = mi.getExpr() and
      mi.getMacroName() in [
          "TypedData_Get_Struct", "RTYPEDDATA_GET_DATA", "RTYPEDDATA_DATA",
          "Data_Get_Struct", "rb_check_typeddata",
          "TypedData_Make_Struct", "TypedData_Wrap_Struct", "Data_Make_Struct", "Data_Wrap_Struct",
          "rb_data_typed_object_make", "rb_data_typed_object_wrap", "rb_data_object_make",
          "rb_data_object_wrap"
        ]
    )
    then result = "typed_data"
    else
      if exists(InnerPointerTakingMacroInvocation mi |
        innerPointerTaking = mi.getExpr() and
        mi.getMacroName() = "FilePathValue"
      )
      then result = "filepath"
      else result = "other"
}

string derivationName(InnerPointerTakingExpr innerPointerTaking) {
  exists(InnerPointerTakingMacroInvocation mi |
    innerPointerTaking = mi.getExpr() and
    result = mi.getMacroName()
  )
  or
  exists(FunctionCall fc |
    innerPointerTaking = fc and
    result = fc.getTarget().getName()
  )
  or
  result = "<expr>"
}

string callName(Call c) {
  exists(FunctionCall fc |
    c = fc and
    result = fc.getTarget().getName()
  )
  or
  exists(ExprCall ec |
    c = ec and
    result = ec.getExpr().toString()
  )
}

from
  ValueVariable v, Function f, string witness_kind, string derivation_family,
  string derivation_name, string trigger_name, string pointer_name,
  Location vloc, Location derivation_loc, Location trigger_loc, Location use_loc
where
  isGuardCandidate(v) and
  needsGuard(v) and
  not hasGuard(v) and
  f = v.getParentScope*().(Function) and
  vloc = v.getLocation() and
  (
    exists(
      GcTriggerCall gtc, PointerVariable innerPointer, PointerVariableAccess pointerUsageAccess,
      InnerPointerTakingExpr innerPointerTaking
    |
      needsGuard(v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking) and
      witness_kind = "intra_pointer_use" and
      derivation_family = witnessFamily(innerPointerTaking) and
      derivation_name = derivationName(innerPointerTaking) and
      trigger_name = callName(gtc) and
      pointer_name = innerPointer.getName() and
      derivation_loc = innerPointerTaking.getLocation() and
      trigger_loc = gtc.getLocation() and
      use_loc = pointerUsageAccess.getLocation()
    )
    or
    exists(
      GcTriggerCall gtc, PointerVariable innerPointer, PointerVariableAccess pointerUsageAccess,
      InnerPointerTakingExpr innerPointerTaking
    |
      innerPointerVariablePassedToTrigger(
        v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking
      ) and
      witness_kind = "passed_to_trigger" and
      derivation_family = witnessFamily(innerPointerTaking) and
      derivation_name = derivationName(innerPointerTaking) and
      trigger_name = callName(gtc) and
      pointer_name = innerPointer.getName() and
      derivation_loc = innerPointerTaking.getLocation() and
      trigger_loc = gtc.getLocation() and
      use_loc = pointerUsageAccess.getLocation()
    )
    or
    exists(GcTriggerCall gtc, InnerPointerTakingExpr innerPointerTaking |
      innerPointerExpressionPassedToTrigger(v, gtc, innerPointerTaking) and
      witness_kind = "passed_to_trigger" and
      derivation_family = witnessFamily(innerPointerTaking) and
      derivation_name = derivationName(innerPointerTaking) and
      trigger_name = callName(gtc) and
      pointer_name = "<direct>" and
      derivation_loc = innerPointerTaking.getLocation() and
      trigger_loc = gtc.getLocation() and
      use_loc = gtc.getLocation()
    )
  )
select
  v, f, witness_kind, derivation_family, derivation_name, trigger_name, pointer_name,
  vloc, derivation_loc, trigger_loc, use_loc
