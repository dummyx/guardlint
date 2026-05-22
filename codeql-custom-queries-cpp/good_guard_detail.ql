import cpp
import lib.guard_checker
import lib.types

from GuardSite guard, ValueVariable v, Function f, string guard_kind, Location vloc, Location guard_loc
where
  reportableGuardSiteForTarget(guard, v) and
  guardCoversModeledObligation(guard) and
  f = v.getParentScope*().(Function) and
  vloc = v.getLocation() and
  guard_kind = guard.getKind() and
  guard_loc = guard.getGuardLocation()
select guard, v, f, guard_kind, vloc, guard_loc
