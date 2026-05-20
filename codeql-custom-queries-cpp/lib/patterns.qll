import guard_checker
import types
import cpp
import semmle.code.cpp.Macro
import semmle.code.cpp.exprs.Access
import semmle.code.cpp.controlflow.ControlFlowGraph

/**
 * Checks if there's an assignment where the RValue involves an InnerPointerTakingFunctionByNameCall
 * that takes the given ValueVariable as an argument, and assigns to the given PointerVariable.
 * ```
 * VALUE a;
 * ptr* b;
 * b = inner_pointer_taking_function(a);
 * ```
 */
predicate hasInnerPointerAssignment(
  ValueVariable v, PointerVariable innerPointer,
  InnerPointerTakingExpr innerPointerTaking
) {
  exists(Assignment assignment |
    assignment.getLValue().(VariableAccess).getTarget() = innerPointer and
    exprIsOrCastsTo(assignment.getRValue(), innerPointerTaking) and
    innerPointerTakingUsesValue(innerPointerTaking, v)
  )
}

/**
 * Checks if there's a declaration of a PointerVariable initialized with an InnerPointerTakingExpr
 * that uses the given ValueVariable as an argument.
 *
 * ```
 * VALUE a;
 * const VALUE *b = RARRAY_CONST_PTR(a);
 * ```
 */
predicate hasInnerPointerDeclaration(
  ValueVariable v, PointerVariable innerPointer,
  InnerPointerTakingExpr innerPointerTaking
) {
  exists(VariableDeclarationEntry declEntry |
    declEntry.getVariable() = innerPointer and
    exprIsOrCastsTo(innerPointer.getInitializer().getExpr(), innerPointerTaking) and
    innerPointerTakingUsesValue(innerPointerTaking, v)
  )
}

predicate macroInvocationUsesValue(InnerPointerTakingMacroInvocation mi, ValueVariable v) {
  mi.getEnclosingFunction() = v.getParentScope*().(Function) and
  (
    exists(ValueAccess va |
      mi.getExpr().getAChild*() = va and
      va.getTarget() = v
    )
    or
    mi.getUnexpandedArgument(0).regexpMatch(".*\\b" + v.getName() + "\\b.*")
  )
}

predicate macroArgumentMentionsVariable(MacroInvocation mi, int idx, Variable v) {
  mi.getUnexpandedArgument(idx).regexpMatch(".*\\b" + v.getName() + "\\b.*")
}

predicate macroOwnerArgument(InnerPointerTakingMacroInvocation mi, int idx) {
  idx = 0 and
  mi.getMacroName() in [
      "BDIGITS",
      "BIGNUM_DIGITS",
      "RSTRING_PTR",
      "RSTRING_END",
      "RSTRING_GETMEM",
      "RARRAY_PTR",
      "RARRAY_CONST_PTR",
      "RARRAY_PTR_USE",
      "DATA_PTR",
      "Data_Get_Struct",
      "RTYPEDDATA_DATA",
      "RTYPEDDATA_GET_DATA",
      "TypedData_Get_Struct",
      "rb_check_typeddata",
      "RREGEXP_PTR",
      "RREGEXP_SRC_PTR",
      "RSTRUCT_PTR",
      "ROBJECT_IVPTR",
      "RFILE",
      "RB_IO_POINTER",
      "GetOpenFile",
      "RMATCH",
      "RMATCH_EXT",
      "RMATCH_REGS",
      "StringValuePtr",
      "StringValueCStr",
      "FilePathValue"
    ]
}

predicate macroOutParamArgument(InnerPointerTakingMacroInvocation mi, int idx) {
  mi.getMacroName() = "RSTRING_GETMEM" and idx = 1
  or
  mi.getMacroName() = "RB_IO_POINTER" and idx = 1
  or
  mi.getMacroName() = "GetOpenFile" and idx = 1
  or
  mi.getMacroName() = "Data_Get_Struct" and idx = 2
  or
  mi.getMacroName() = "TypedData_Get_Struct" and idx = 3
}

predicate macroInvocationOwnerIsValue(InnerPointerTakingMacroInvocation mi, ValueVariable v) {
  exists(int idx |
    macroOwnerArgument(mi, idx) and
    macroArgumentMentionsVariable(mi, idx, v)
  )
  or
  (
    not exists(int idx | macroOwnerArgument(mi, idx)) and
    macroInvocationUsesValue(mi, v)
  )
}

predicate macroInvocationOutParamIsPointer(
  InnerPointerTakingMacroInvocation mi, PointerVariable innerPointer
) {
  exists(int idx |
    macroOutParamArgument(mi, idx) and
    macroArgumentMentionsVariable(mi, idx, innerPointer)
  )
}

predicate hasInnerPointerMacroExpansionAssignment(
  ValueVariable v, PointerVariable innerPointer,
  InnerPointerTakingExpr innerPointerTaking
) {
  exists(InnerPointerTakingMacroInvocation mi, Assignment assign |
    mi.getMacroName() in ["RSTRING_GETMEM", "RB_IO_POINTER", "GetOpenFile", "Data_Get_Struct", "TypedData_Get_Struct"] and
    mi.getAnExpandedElement() = assign and
    assign.getLValue().(VariableAccess).getTarget() = innerPointer and
    exprIsOrCastsTo(assign.getRValue(), innerPointerTaking) and
    macroInvocationOwnerIsValue(mi, v) and
    (
      macroInvocationOutParamIsPointer(mi, innerPointer)
      or
      not exists(int idx | macroOutParamArgument(mi, idx))
    )
  )
}

predicate hasMacroOutParamByExpansion(
  ValueVariable v, PointerVariable innerPointer,
  InnerPointerTakingExpr innerPointerTaking
) {
  exists(InnerPointerTakingMacroInvocation mi, Assignment assign |
    mi.getMacroName() in ["RSTRING_GETMEM", "RB_IO_POINTER", "GetOpenFile", "Data_Get_Struct", "TypedData_Get_Struct"] and
    innerPointerTaking = mi.getExpr() and
    mi.getAnExpandedElement() = assign and
    assign.getLValue().(VariableAccess).getTarget() = innerPointer and
    macroInvocationOwnerIsValue(mi, v) and
    macroInvocationOutParamIsPointer(mi, innerPointer)
  )
}

predicate innerPointerTakingUsesValue(InnerPointerTakingExpr innerPointerTaking, ValueVariable v) {
  exists(InnerPointerTakingFunctionByNameCall fc |
    fc = innerPointerTaking and
    fc.getAnArgument().(ValueAccess).getTarget() = v
  )
  or
  exists(FunctionCall fc |
    fc = innerPointerTaking and
    fc.getTarget() instanceof InnerPointerGetterFunction and
    fc.getAnArgument().getAChild*().(ValueAccess).getTarget() = v
  )
  or
  exists(InnerPointerTakingMacroInvocation mi |
    innerPointerTaking = mi.getExpr() and
    macroInvocationOwnerIsValue(mi, v)
  )
}

/**
 * Checks if there's an InnerPointerTakingFunctionByNameCall that takes both the ValueVariable
 * and the PointerVariable as arguments (directly or through field access).
 * ```
 * VALUE a;
 * ptr* b;
 * inner_pointer_taking_function(a, b);
 * ```
 */
predicate hasInnerPointerFunctionCall(
  ValueVariable v, PointerVariable innerPointer,
  InnerPointerTakingExpr innerPointerTaking
) {
  exists(InnerPointerTakingFunctionByNameCall fc |
    fc = innerPointerTaking and
    (
      fc.getAnArgument().(ValueAccess).getTarget() = v
    ) and
    fc.getAnArgument().(PointerVariableAccess).getTarget() = innerPointer
  )
}

/**
 * Checks if any of the inner pointer patterns exist for the given variables.
 */
predicate hasInnerPointerTaken(
  ValueVariable v, PointerVariable innerPointer,
  InnerPointerTakingExpr innerPointerTaking
) {
  hasInnerPointerAssignment(v, innerPointer, innerPointerTaking)
  or
  hasInnerPointerDeclaration(v, innerPointer, innerPointerTaking)
  or
  hasInnerPointerFunctionCall(v, innerPointer, innerPointerTaking)
  or
  hasInnerPointerMacroExpansionAssignment(v, innerPointer, innerPointerTaking)
  or
  hasMacroOutParamByExpansion(v, innerPointer, innerPointerTaking)
}

/**
 * Holds if `usageNode` is reachable *after* `gcTriggerCall` in the CFG.
 *
 * This avoids common false positives when `usageNode` is an argument expression
 * of `gcTriggerCall` (arguments are evaluated before the call).
 */
pragma[inline]
predicate isPointerUsedAfterCall(ControlFlowNode usageNode, Call call) {
  usageNode.getControlFlowScope() = call.getControlFlowScope() and
  call.getASuccessor+() = usageNode
}

pragma[inline]
predicate isPointerUsedAfterGcTrigger(ControlFlowNode usageNode, GcTriggerCall gcTriggerCall) {
  isPointerUsedAfterCall(usageNode, gcTriggerCall)
}

predicate pointerUseOnlyComputesScalarOffset(PointerVariableAccess use) {
  exists(PointerDiffExpr diff |
    diff.getAChild*() = use
  )
}

/**
 * Holds when the modeled pointer access is only part of an assignment lvalue.
 *
 * Such an access writes/rebinds the pointer variable; it is not a read of the
 * previously derived subordinate pointer.
 */
predicate pointerAccessOnlyWritesPointer(PointerVariableAccess use) {
  exists(Assignment assign |
    assign.getLValue().getAChild*() = use
  )
}

/*
 * predicate passedToGcTrigger(ValueVariable v, ValueAccess initVAccess, FunctionCall gcTriggerCall) {
 *  exists(int i |
 *    initVAccess = v.getAnAccess() and
 *    i < count(gcTriggerCall.getAnArgument()) and
 *    gcTriggerCall.getAnArgumentSubExpr(i) = v.getAnAccess() and
 *    isArgumentNotSafe(gcTriggerCall.getTarget(), i)
 *  )
 * }
 */

predicate notAccessedAfterCall(ValueVariable v, Call call) {
  not exists(VariableAccess va |
    va.getTarget() = v and
    va.getControlFlowScope() = call.getControlFlowScope() and
    isPointerUsedAfterCall(va, call) and
    va.getLocation().getStartLine() > call.getLocation().getEndLine() and
    not isGuardAccess(va) and
    isValuePassedToCallAfter(va, call)
  )
}

predicate notAccessedAfterGcTrigger(ValueVariable v, GcTriggerCall gcTriggerCall) {
  notAccessedAfterCall(v, gcTriggerCall)
}

predicate isValuePassedToCallAfter(ValueAccess va, Call afterCall) {
  exists(FunctionCall call |
    call.getControlFlowScope() = afterCall.getControlFlowScope() and
    call.getLocation().getStartLine() > afterCall.getLocation().getEndLine() and
    not isHoistableFunction(call.getTarget()) and
    exists(Expr arg | call.getAnArgument() = arg and exprIsOrCastsTo(arg, va))
  )
  or
  exists(ExprCall call |
    call.getControlFlowScope() = afterCall.getControlFlowScope() and
    call.getLocation().getStartLine() > afterCall.getLocation().getEndLine() and
    exists(Expr arg | call.getAnArgument() = arg and exprIsOrCastsTo(arg, va))
  )
}

predicate isValuePassedToCallAfterGcTrigger(ValueAccess va, GcTriggerCall afterCall) {
  isValuePassedToCallAfter(va, afterCall)
}

predicate isHoistableFunction(Function function) {
  exists(Attribute attr |
    attr = function.getAnAttribute() and
    attr.hasName(["pure", "const"])
  )
}

/**
 * Holds if `p` is (re)assigned after `gcTriggerCall` on some path to `use`.
 *
 * This prevents false positives where a pointer variable is reused and
 * overwritten after the GC trigger (e.g., `GetOpenFile(x, fptr)` occurs again),
 * so the post-GC use does not actually refer to the pre-GC derived pointer.
 */
pragma[inline]
predicate pointerReassignedAfterGcBeforeUse(
  PointerVariable p, GcTriggerCall gcTriggerCall, PointerVariableAccess use
) {
  exists(Assignment assign |
    assign.getControlFlowScope() = gcTriggerCall.getControlFlowScope() and
    assign.getLValue().getAChild*().(VariableAccess).getTarget() = p and
    isPointerUsedAfterGcTrigger(assign, gcTriggerCall) and
    assign.getASuccessor*() = use
  )
}
