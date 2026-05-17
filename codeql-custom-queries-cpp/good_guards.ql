import cpp
import lib.guard_checker
import lib.types

from GuardSite guard, ValueVariable v
where
  guard.getValue() = v and
  guard.isReportable() and
  isTarget(v) and
  guardCoversModeledObligation(guard)
select guard, v, guard.getKind(), guard.getGuardLocation()
