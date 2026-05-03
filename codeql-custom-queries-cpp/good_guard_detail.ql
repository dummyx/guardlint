import cpp
import lib.guard_checker
import lib.types

predicate hasGuardMacro(ValueVariable v, MacroInvocation mi) {
  exists(ValueAccess va |
    mi.getMacroName() = "RB_GC_GUARD" and
    mi.getAnExpandedElement() = va and
    va.getTarget() = v
  )
}

predicate hasGuardDecl(ValueVariable v, VariableDeclarationEntry decl) {
  decl.getVariable()
      .getInitializer()
      .getExpr()
      .(AddressOfExpr)
      .getAnOperand()
      .(VariableAccess)
      .getTarget() = v and
  decl.getVariable().getName() = "rb_gc_guarded_ptr"
}

predicate hasGuardCall(ValueVariable v, FunctionCall call) {
  (
    call.getTarget().getName() = "rb_gc_guarded_ptr" and
    exists(AddressOfExpr addr |
      call.getAnArgument().getAChild*() = addr and
      addr.getAnOperand().(ValueAccess).getTarget() = v
    )
  )
  or
  (
    call.getTarget().getName() = "rb_gc_guarded_ptr_val" and
    exists(AddressOfExpr addr |
      call.getAnArgumentSubExpr(0).getAChild*() = addr and
      addr.getAnOperand().(ValueAccess).getTarget() = v
    )
  )
}

from ValueVariable v, Function f, string guard_kind, Location vloc, Location guard_loc
where
  isGuardCandidate(v) and
  needsGuard(v) and
  hasGuard(v) and
  f = v.getParentScope*().(Function) and
  vloc = v.getLocation() and
  (
    exists(MacroInvocation mi |
      hasGuardMacro(v, mi) and
      guard_kind = "RB_GC_GUARD" and
      guard_loc = mi.getLocation()
    )
    or
    exists(VariableDeclarationEntry decl |
      hasGuardDecl(v, decl) and
      guard_kind = "rb_gc_guarded_ptr decl" and
      guard_loc = decl.getLocation()
    )
    or
    exists(FunctionCall call |
      hasGuardCall(v, call) and
      guard_kind = call.getTarget().getName() and
      guard_loc = call.getLocation()
    )
  )
select v, f, guard_kind, vloc, guard_loc
