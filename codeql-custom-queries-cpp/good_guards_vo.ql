import cpp
import lib.guard_checker
import lib.types

from ValueVariable v
where exists(GuardSite guard |
  guard.getValue() = v and
  guard.isReportable() and
  isTarget(v) and
  guardCoversModeledObligation(guard)
)
select v
