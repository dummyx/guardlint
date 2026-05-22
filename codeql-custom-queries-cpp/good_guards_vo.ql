import cpp
import lib.guard_checker
import lib.types

from ValueVariable v
where exists(GuardSite guard |
  reportableGuardSiteForTarget(guard, v) and
  guardCoversModeledObligation(guard)
)
select v
