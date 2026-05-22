import cpp
import lib.guard_checker
import lib.types

from GuardSite guard, ValueVariable v
where
  reportableGuardSiteForTarget(guard, v) and
  guardCoversModeledObligation(guard)
select guard, v, guard.getKind(), guard.getGuardLocation()
