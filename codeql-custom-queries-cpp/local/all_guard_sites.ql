import cpp
import lib.guard_checker
import lib.types
import semmle.code.cpp.Macro

string reportableStatus(GuardSite guard) {
  if guard.isReportable()
  then result = "reportable"
  else result = "internal_or_nonreportable"
}

string targetStatus(ValueVariable v) {
  if isTarget(v)
  then result = "target_scope"
  else result = "outside_target_scope"
}

from GuardSite guard, ValueVariable v, Function f
where
  guardSiteForValue(guard, v) and
  f = v.getParentScope*().(Function)
select
  guard, v, f, guard.getKind(), guard.getGuardLocation(),
  reportableStatus(guard), targetStatus(v)
