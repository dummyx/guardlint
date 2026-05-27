import cpp
import lib.guard_checker
import lib.exclusion_audit
import lib.types

from
  ValueVariable v, Function f, Location vloc, string exclusion_reason,
  string obligation_status, string guard_status
where
  f = v.getParentScope*().(Function) and
  vloc = v.getLocation() and
  guardAnalysisExclusionReason(v, exclusion_reason) and
  obligation_status = "see_excluded_missing_sensitivity" and
  (
    exists(GuardSite guard | guardSiteForValue(guard, v)) and guard_status = "has_guard_site"
    or
    not exists(GuardSite guard | guardSiteForValue(guard, v)) and guard_status = "no_guard_site"
  )
select v, f, vloc, exclusion_reason, obligation_status, guard_status
