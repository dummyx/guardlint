import cpp
import lib.guard_checker

from
  ValueVariable v, Function f, string guard_kind, Location vloc, Location guard_loc
where
  isGuardCandidate(v) and
  hasReportableGuard(v) and
  not needsGuard(v) and
  f = v.getParentScope*().(Function) and
  vloc = v.getLocation() and
  (
    exists(MacroInvocation mi |
      hasReportableGuardMacro(v, mi) and
      guard_kind = mi.getMacroName() and
      guard_loc = mi.getLocation()
    )
    or
    exists(VariableDeclarationEntry decl |
      hasReportableGuardDecl(v, decl) and
      guard_kind = "rb_gc_guarded_ptr" and
      guard_loc = decl.getLocation()
    )
    or
    exists(FunctionCall call |
      hasReportableGuardCall(v, call) and
      guard_kind = call.getTarget().getName() and
      guard_loc = call.getLocation()
    )
  )
select v, f, guard_kind, vloc, guard_loc
