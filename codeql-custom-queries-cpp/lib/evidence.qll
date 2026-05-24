import cpp
import guard_checker
import types

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

string pointerPassedWitnessKind(Call c) {
  if exists(FunctionCall fc | c = fc and isScanArgsCall(fc))
  then result = "passed_to_consumer"
  else result = "passed_to_trigger"
}
