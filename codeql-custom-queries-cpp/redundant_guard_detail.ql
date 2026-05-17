import cpp
import lib.guard_checker

from
  GuardSite guard, ValueVariable v, Function f, string guard_kind, Location vloc, Location guard_loc
where
  guard.getValue() = v and
  guard.isReportable() and
  isTarget(v) and
  not guardCoversModeledObligation(guard) and
  f = v.getParentScope*().(Function) and
  vloc = v.getLocation() and
  guard_kind = guard.getKind() and
  guard_loc = guard.getGuardLocation()
select guard, v, f, guard_kind, vloc, guard_loc
