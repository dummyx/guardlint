import cpp
import lib.evidence
import lib.guard_checker
import lib.types

from
  GuardSite guard, ValueVariable v, Function f, string guard_kind,
  string witness_kind, string derivation_family, string derivation_name,
  string trigger_name, string pointer_name, string target_reason, string trigger_reason,
  Location vloc, Location guard_loc, Location derivation_loc, Location trigger_loc, Location use_loc
where
  reportableGuardSiteForTarget(guard, v) and
  f = v.getParentScope*().(Function) and
  vloc = v.getLocation() and
  guard_kind = guard.getKind() and
  guard_loc = guard.getGuardLocation() and
  (
    exists(
      GcTriggerCall gtc, PointerVariable innerPointer, PointerVariableAccess pointerUsageAccess,
      InnerPointerTakingExpr innerPointerTaking
    |
      basePointerUseObligation(
        v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking
      ) and
      coveredByGuard(v, innerPointer, innerPointerTaking, gtc, pointerUsageAccess, guard) and
      witness_kind = "intra_pointer_use" and
      derivation_family = witnessFamily(innerPointerTaking) and
      derivation_name = derivationName(innerPointerTaking) and
      trigger_name = callName(gtc) and
      target_reason = targetReason(v) and
      trigger_reason = gcTriggerReason(gtc) and
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
      basePointerVariablePassedToTriggerObligation(
        v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking
      ) and
      coveredByGuardAtTriggerUse(v, innerPointerTaking, gtc, guard) and
      witness_kind = pointerPassedWitnessKind(gtc) and
      derivation_family = witnessFamily(innerPointerTaking) and
      derivation_name = derivationName(innerPointerTaking) and
      trigger_name = callName(gtc) and
      target_reason = targetReason(v) and
      trigger_reason = gcTriggerReason(gtc) and
      pointer_name = innerPointer.getName() and
      derivation_loc = innerPointerTaking.getLocation() and
      trigger_loc = gtc.getLocation() and
      use_loc = gtc.getLocation()
    )
    or
    exists(GcTriggerCall gtc, InnerPointerTakingExpr innerPointerTaking |
      baseInnerPointerExpressionPassedToTriggerObligation(v, gtc, innerPointerTaking) and
      coveredByGuardAtTriggerUse(v, innerPointerTaking, gtc, guard) and
      witness_kind = pointerPassedWitnessKind(gtc) and
      derivation_family = witnessFamily(innerPointerTaking) and
      derivation_name = derivationName(innerPointerTaking) and
      trigger_name = callName(gtc) and
      target_reason = targetReason(v) and
      trigger_reason = gcTriggerReason(gtc) and
      pointer_name = "<direct>" and
      derivation_loc = innerPointerTaking.getLocation() and
      trigger_loc = gtc.getLocation() and
      use_loc = gtc.getLocation()
    )
    or
    (
      needsGuardKnownRequiredGuardSites(v) and
      witness_kind = "known_required_guard_site" and
      derivation_family = "model_override" and
      derivation_name = "<none>" and
      trigger_name = "<none>" and
      pointer_name = "<none>" and
      target_reason = targetReason(v) and
      trigger_reason = "known_required_guard_site" and
      derivation_loc = guard.getGuardLocation() and
      trigger_loc = guard.getGuardLocation() and
      use_loc = guard.getGuardLocation()
    )
  )
select
  guard, v, f, guard_kind, witness_kind, derivation_family, derivation_name,
  trigger_name, pointer_name, vloc, guard_loc, derivation_loc, trigger_loc, use_loc,
  target_reason, trigger_reason
