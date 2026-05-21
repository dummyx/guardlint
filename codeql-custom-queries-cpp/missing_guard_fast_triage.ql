import cpp
import lib.guard_checker
import lib.patterns
import lib.types

/**
 * Fast source-order triage for release monitoring.
 *
 * This query intentionally avoids the full CFG-based covering-guard check used
 * by missing_guards.ql. It is meant to produce a bounded review queue on large
 * release databases when the authoritative witness-sensitive query does not
 * finish. Rows from this query are candidates, not paper counts.
 */

pragma[inline]
predicate sameFunction(ValueVariable v, ControlFlowNode node) {
  node.getControlFlowScope() = v.getParentScope*().(Function)
}

pragma[inline]
predicate before(Element first, Element second) {
  first.getLocation().getEndLine() <= second.getLocation().getStartLine()
}

predicate ownerAccessAfterTrigger(ValueVariable v, GcTriggerCall gtc) {
  exists(ValueAccess va |
    va.getTarget() = v and
    va.getControlFlowScope() = gtc.getControlFlowScope() and
    before(gtc, va) and
    not isGuardAccess(va)
  )
}

predicate pointerReassignedAfterTriggerBeforeUseByLocation(
  PointerVariable p, GcTriggerCall gtc, PointerVariableAccess use
) {
  exists(Assignment assign |
    assign.getControlFlowScope() = gtc.getControlFlowScope() and
    assign.getLValue().getAChild*().(VariableAccess).getTarget() = p and
    before(gtc, assign) and
    not before(use, assign)
  )
}

predicate hasSourceOrderCoveringGuard(ValueVariable v, ControlFlowNode useNode) {
  exists(GuardSite guard |
    guard.getValue() = v and
    before(useNode, guard)
  )
}

predicate fastIntraPointerWitness(
  ValueVariable v, PointerVariable p, GcTriggerCall gtc, PointerVariableAccess use,
  InnerPointerTakingExpr it
) {
  isTarget(v) and
  not (v instanceof Parameter and v.getName() = "self") and
  not valueLoadedFromMarkedThreadProcField(v) and
  sameFunction(v, gtc) and
  sameFunction(v, it) and
  sameFunction(v, use) and
  p != v and
  pointerUsageTarget(use, p) and
  hasInnerPointerTaken(v, p, it) and
  before(it, gtc) and
  before(gtc, use) and
  not pointerUseOnlyComputesScalarOffset(use) and
  not pointerAccessOnlyWritesPointer(use) and
  not pointerReassignedAfterTriggerBeforeUseByLocation(p, gtc, use) and
  not ownerAnchoredByEnclosingCall(v, gtc, use) and
  not ownerAccessAfterTrigger(v, gtc) and
  not isScanArgsSafeToIgnore(v, it) and
  not hasSourceOrderCoveringGuard(v, use)
}

predicate pointerUsageTarget(PointerVariableAccess use, PointerVariable p) {
  use.getTarget() = p
}

string witnessFamily(InnerPointerTakingExpr it) {
  if isStringInnerPointerTaking(it)
  then result = "string"
  else
    if isArrayInnerPointerTaking(it)
    then result = "array"
    else result = "other"
}

string derivationName(InnerPointerTakingExpr it) {
  exists(InnerPointerTakingMacroInvocation mi |
    it = mi.getExpr() and
    result = mi.getMacroName()
  )
  or
  exists(FunctionCall fc |
    it = fc and
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
  f = v.getParentScope*().(Function) and
  vloc = v.getLocation() and
  (
    exists(PointerVariable p, GcTriggerCall gtc, PointerVariableAccess use, InnerPointerTakingExpr it |
      fastIntraPointerWitness(v, p, gtc, use, it) and
      witness_kind = "source_order_intra_pointer_use" and
      derivation_family = witnessFamily(it) and
      derivation_name = derivationName(it) and
      trigger_name = callName(gtc) and
      pointer_name = p.getName() and
      derivation_loc = it.getLocation() and
      trigger_loc = gtc.getLocation() and
      use_loc = use.getLocation()
    )
  )
select
  v, f, witness_kind, derivation_family, derivation_name, trigger_name, pointer_name,
  vloc, derivation_loc, trigger_loc, use_loc
