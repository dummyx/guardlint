import cpp
import lib.guard_checker

from GuardSite guard, ValueVariable v
where
  guard.getValue() = v and
  guard.isReportable() and
  isTarget(v) and
  not guardCoversModeledObligation(guard)
select guard, v, guard.getKind(), guard.getGuardLocation()
