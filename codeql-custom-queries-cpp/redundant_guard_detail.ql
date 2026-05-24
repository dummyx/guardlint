import cpp
import lib.guard_checker
import lib.types

from
  GuardSite guard, ValueVariable v, Function f, string guard_kind,
  string covers_modeled_obligation, Location vloc, Location guard_loc
where
  reportableGuardSiteForTarget(guard, v) and
  not guardCoversModeledObligation(guard) and
  f = v.getParentScope*().(Function) and
  vloc = v.getLocation() and
  guard_kind = guard.getKind() and
  guard_loc = guard.getGuardLocation() and
  covers_modeled_obligation = "false"
select guard, v, f, guard_kind, covers_modeled_obligation, vloc, guard_loc
