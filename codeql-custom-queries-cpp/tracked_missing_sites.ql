import cpp
import lib.guard_checker

predicate isTrackedSite(Function f, ValueVariable v, string siteLabel) {
  f.getName() = "rb_str_format_m" and v.getName() = "tmp" and siteLabel = "rb_str_format_m"
  or
  f.getName() = "io_buffer_set_string" and v.getName() = "string" and siteLabel = "io_buffer_set_string"
  or
  f.getName() = "location_format" and v.getName() = "name" and siteLabel = "location_format"
  or
  f.getName() = "search_required" and v.getName() = "lookup_name" and siteLabel = "search_required/lookup_name"
  or
  f.getName() = "rb_str_buf_append" and v.getName() = "str2" and siteLabel = "rb_str_buf_append/str2"
  or
  f.getName() = "iseq_build_from_ary_body" and v.getName() = "labels_wrapper" and siteLabel = "iseq_build_from_ary_body/labels_wrapper"
  or
  f.getName() = "scan_once" and v.getName() = "match" and siteLabel = "scan_once/match"
}

from ValueVariable v, Function f, string siteLabel, Location vloc
where
  isGuardCandidate(v) and
  needsGuard(v) and
  not hasGuard(v) and
  f = v.getParentScope*().(Function) and
  isTrackedSite(f, v, siteLabel) and
  vloc = v.getLocation()
select siteLabel, v, f, vloc
