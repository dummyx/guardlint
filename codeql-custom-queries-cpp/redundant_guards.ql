import cpp
import lib.guard_checker

from GuardSite guard, ValueVariable v
where
  reportableGuardSiteForTarget(guard, v) and
  not guardCoversModeledObligation(guard)
select guard, v, guard.getKind(), guard.getGuardLocation()
