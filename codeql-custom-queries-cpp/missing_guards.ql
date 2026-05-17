import cpp
import lib.guard_checker
import lib.patterns
import lib.types

string pointerPassedWitnessKind(Call c) {
  if exists(FunctionCall fc | c = fc and isScanArgsCall(fc))
  then result = "passed_to_consumer"
  else result = "passed_to_trigger"
}

from
  ValueVariable v, Function f, string witness_kind,
  Location derivation_loc, Location trigger_loc, Location use_loc
where
  isGuardCandidate(v) and
  f = v.getParentScope*().(Function) and
  (
    exists(
      GcTriggerCall gtc, PointerVariable innerPointer, PointerVariableAccess pointerUsageAccess,
      InnerPointerTakingExpr innerPointerTaking
    |
      needsGuard(v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking) and
      not hasCoveringGuard(v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking) and
      witness_kind = "intra_pointer_use" and
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
      not hasCoveringGuardAtTriggerUse(v, gtc, innerPointerTaking) and
      witness_kind = pointerPassedWitnessKind(gtc) and
      derivation_loc = innerPointerTaking.getLocation() and
      trigger_loc = gtc.getLocation() and
      use_loc = gtc.getLocation()
    )
    or
    exists(GcTriggerCall gtc, InnerPointerTakingExpr innerPointerTaking |
      innerPointerExpressionPassedToTrigger(v, gtc, innerPointerTaking) and
      not hasCoveringGuardAtTriggerUse(v, gtc, innerPointerTaking) and
      witness_kind = pointerPassedWitnessKind(gtc) and
      derivation_loc = innerPointerTaking.getLocation() and
      trigger_loc = gtc.getLocation() and
      use_loc = gtc.getLocation()
    )
  )
select
  v, f, witness_kind, derivation_loc, trigger_loc, use_loc
