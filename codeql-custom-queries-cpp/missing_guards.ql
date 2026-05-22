import cpp
import lib.guard_checker
import lib.patterns
import lib.types

from ValueVariable v, Function f, Location vloc
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
      not hasCoveringGuard(v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking)
    )
    or
    exists(
      GcTriggerCall gtc, PointerVariable innerPointer, PointerVariableAccess pointerUsageAccess,
      InnerPointerTakingExpr innerPointerTaking
    |
      basePointerVariablePassedToTriggerObligation(
        v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking
      ) and
      not hasCoveringGuardAtTriggerUse(v, gtc, innerPointerTaking)
    )
    or
    exists(GcTriggerCall gtc, InnerPointerTakingExpr innerPointerTaking |
      baseInnerPointerExpressionPassedToTriggerObligation(v, gtc, innerPointerTaking) and
      not hasCoveringGuardAtTriggerUse(v, gtc, innerPointerTaking)
    )
  )
select v, f, vloc
