import cpp
import lib.guard_checker

from ValueVariable v
where
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
select v
