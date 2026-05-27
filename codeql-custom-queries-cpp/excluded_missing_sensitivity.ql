import cpp
import lib.evidence
import lib.guard_checker
import lib.exclusion_audit
import lib.types

from
  ValueVariable v, Function f, string exclusion_reason, string witness_kind,
  string derivation_family, string derivation_name, string trigger_name, string pointer_name,
  string target_reason, string trigger_reason, string non_covering_guard_kind,
  string non_covering_guard_loc, string non_covering_guard_reason,
  Location vloc, Location derivation_loc, Location trigger_loc, Location use_loc
where
  f = v.getParentScope*().(Function) and
  vloc = v.getLocation() and
  exclusion_reason = "see_excluded_value_inventory" and
  exists(
    GcTriggerCall gtc, PointerVariable innerPointer, PointerVariableAccess pointerUsageAccess,
    InnerPointerTakingExpr innerPointerTaking
  |
    isExcludedGuardAnalysisTarget(v) and
    gtc.getControlFlowScope() = f and
    innerPointerTaking.getControlFlowScope() = f and
    innerPointer != v and
    not innerPointer instanceof GuardedPtr and
    hasInnerPointerTaken(v, innerPointer, innerPointerTaking) and
    innerPointerTaking.getLocation().getEndLine() <= gtc.getLocation().getStartLine() and
    pointerUsageAccess.getTarget() = innerPointer and
    pointerUsageAccess.getLocation().getStartLine() > gtc.getLocation().getEndLine() and
    not pointerAccessOnlyWritesPointer(pointerUsageAccess) and
    not exists(GuardSite guard | guardSiteForValue(guard, v)) and
    witness_kind = "source_order_scope_sensitivity" and
    derivation_family = witnessFamily(innerPointerTaking) and
    derivation_name = derivationName(innerPointerTaking) and
    trigger_name = callName(gtc) and
    target_reason = targetReason(v) and
    trigger_reason = gcTriggerReason(gtc) and
    pointer_name = innerPointer.getName() and
    non_covering_guard_kind = "<not_evaluated>" and
    non_covering_guard_loc = "<not_evaluated>" and
    non_covering_guard_reason = "scope_sensitivity_uses_source_order" and
    derivation_loc = innerPointerTaking.getLocation() and
    trigger_loc = gtc.getLocation() and
    use_loc = pointerUsageAccess.getLocation()
  )
select
  v, f, exclusion_reason, witness_kind, derivation_family, derivation_name, trigger_name,
  pointer_name, vloc, derivation_loc, trigger_loc, use_loc, target_reason, trigger_reason,
  non_covering_guard_kind, non_covering_guard_loc, non_covering_guard_reason
