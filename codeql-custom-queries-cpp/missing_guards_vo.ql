import cpp
import lib.guard_checker

from ValueVariable v
where
  isGuardCandidate(v) and
  (
    exists(
      GcTriggerCall gtc, PointerVariable innerPointer, PointerVariableAccess pointerUsageAccess,
      InnerPointerTakingExpr innerPointerTaking
    |
      needsGuard(v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking) and
      not hasCoveringGuard(v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking)
    )
    or
    exists(
      GcTriggerCall gtc, PointerVariable innerPointer, PointerVariableAccess pointerUsageAccess,
      InnerPointerTakingExpr innerPointerTaking
    |
      innerPointerVariablePassedToTrigger(
        v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking
      ) and
      not hasCoveringGuardAtTriggerUse(v, gtc, innerPointerTaking)
    )
    or
    exists(GcTriggerCall gtc, InnerPointerTakingExpr innerPointerTaking |
      innerPointerExpressionPassedToTrigger(v, gtc, innerPointerTaking) and
      not hasCoveringGuardAtTriggerUse(v, gtc, innerPointerTaking)
    )
  )
select v
