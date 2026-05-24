import cpp
import lib.evidence
import lib.guard_checker
import lib.patterns
import lib.types

from
  ValueVariable v, Function f, string witness_kind, string derivation_family,
  string derivation_name, string trigger_name, string pointer_name,
  string target_reason, string trigger_reason, string non_covering_guard_kind,
  string non_covering_guard_loc, string non_covering_guard_reason,
  Location vloc, Location derivation_loc, Location trigger_loc, Location use_loc
where
  f = v.getParentScope*().(Function) and
  vloc = v.getLocation() and
  (
    exists(
      GcTriggerCall gtc, PointerVariable innerPointer, PointerVariableAccess pointerUsageAccess,
      InnerPointerTakingExpr innerPointerTaking
    |
      basePointerUseObligation(
        v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking
      ) and
      not hasCoveringGuard(v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking) and
      witness_kind = "intra_pointer_use" and
      derivation_family = witnessFamily(innerPointerTaking) and
      derivation_name = derivationName(innerPointerTaking) and
      trigger_name = callName(gtc) and
      target_reason = targetReason(v) and
      trigger_reason = gcTriggerReason(gtc) and
      pointer_name = innerPointer.getName() and
      non_covering_guard_kind =
        firstNonCoveringGuardKind(
          v, innerPointer, innerPointerTaking, gtc, pointerUsageAccess
        ) and
      non_covering_guard_loc =
        firstNonCoveringGuardLocation(
          v, innerPointer, innerPointerTaking, gtc, pointerUsageAccess
        ) and
      non_covering_guard_reason =
        firstNonCoveringGuardReason(
          v, innerPointer, innerPointerTaking, gtc, pointerUsageAccess
        ) and
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
      not hasCoveringGuardAtTriggerUse(v, gtc, innerPointerTaking) and
      witness_kind = pointerPassedWitnessKind(gtc) and
      derivation_family = witnessFamily(innerPointerTaking) and
      derivation_name = derivationName(innerPointerTaking) and
      trigger_name = callName(gtc) and
      target_reason = targetReason(v) and
      trigger_reason = gcTriggerReason(gtc) and
      pointer_name = innerPointer.getName() and
      non_covering_guard_kind =
        firstNonCoveringTriggerGuardKind(v, innerPointerTaking, gtc) and
      non_covering_guard_loc =
        firstNonCoveringTriggerGuardLocation(v, innerPointerTaking, gtc) and
      non_covering_guard_reason =
        firstNonCoveringTriggerGuardReason(v, innerPointerTaking, gtc) and
      derivation_loc = innerPointerTaking.getLocation() and
      trigger_loc = gtc.getLocation() and
      use_loc = gtc.getLocation()
    )
    or
    exists(GcTriggerCall gtc, InnerPointerTakingExpr innerPointerTaking |
      baseInnerPointerExpressionPassedToTriggerObligation(v, gtc, innerPointerTaking) and
      not hasCoveringGuardAtTriggerUse(v, gtc, innerPointerTaking) and
      witness_kind = pointerPassedWitnessKind(gtc) and
      derivation_family = witnessFamily(innerPointerTaking) and
      derivation_name = derivationName(innerPointerTaking) and
      trigger_name = callName(gtc) and
      target_reason = targetReason(v) and
      trigger_reason = gcTriggerReason(gtc) and
      pointer_name = "<direct>" and
      non_covering_guard_kind =
        firstNonCoveringTriggerGuardKind(v, innerPointerTaking, gtc) and
      non_covering_guard_loc =
        firstNonCoveringTriggerGuardLocation(v, innerPointerTaking, gtc) and
      non_covering_guard_reason =
        firstNonCoveringTriggerGuardReason(v, innerPointerTaking, gtc) and
      derivation_loc = innerPointerTaking.getLocation() and
      trigger_loc = gtc.getLocation() and
      use_loc = gtc.getLocation()
    )
  )
select
  v, f, witness_kind, derivation_family, derivation_name, trigger_name, pointer_name,
  vloc, derivation_loc, trigger_loc, use_loc, target_reason, trigger_reason,
  non_covering_guard_kind, non_covering_guard_loc, non_covering_guard_reason
