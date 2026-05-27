import cpp
import guard_checker
import types

predicate isTargetCandidate(ValueVariable v) {
  v.getEnclosingElement() instanceof TopLevelFunction
}

predicate targetScopeExclusionReason(ValueVariable v, string reason) {
  isTargetCandidate(v) and
  (
    exists(Function f |
      f = v.getParentScope*().(Function) and
      isInternalCompilerOrStartupFunction(f) and
      reason = "internal_compiler_or_startup_function"
    )
    or
    (
      v instanceof Parameter and
      exists(Function f |
        f = v.getParentScope*().(Function) and
        isBlockCallbackFunction(f) and
        reason = "block_callback_parameter"
      )
    )
    or
    (
      v instanceof Parameter and
      v.getParentScope().(Function).getParameter(0) = v and
      reason = "first_parameter"
    )
    or
    (
      v instanceof Parameter and
      isArgvStyleReceiverParameter(v) and
      reason = "argc_argv_receiver_parameter"
    )
    or
    (
      v instanceof Parameter and
      exists(Function f |
        f = v.getParentScope*().(Function) and
        isRubyCfunc(f) and
        reason = "ruby_cfunc_parameter"
      )
    )
    or
    (
      v.getFile().toString().matches("%.h") and
      reason = "header_declaration"
    )
    or
    (
      v.getADeclarationEntry().isInMacroExpansion() and
      reason = "macro_expanded_declaration"
    )
    or
    (
      v.getFile().toString().matches("%.inc") and
      reason = "inc_declaration"
    )
    or
    (
      v.getFile().toString().matches("%.y") and
      reason = "yacc_source_declaration"
    )
    or
    (
      v.getFile().toString().matches("%.erb") and
      reason = "erb_source_declaration"
    )
    or
    (
      v.getFile().toString().matches("api_nodes.c") and
      reason = "generated_api_nodes"
    )
  )
}

predicate hasReviewableTargetScopeExclusion(ValueVariable v) {
  isTargetCandidate(v) and
  (
    exists(Function f |
      f = v.getParentScope*().(Function) and
      isInternalCompilerOrStartupFunction(f)
    )
    or
    (
      v instanceof Parameter and
      exists(Function f |
        f = v.getParentScope*().(Function) and
        isBlockCallbackFunction(f)
      )
    )
    or
    (
      v instanceof Parameter and
      v.getParentScope().(Function).getParameter(0) = v
    )
    or
    (
      v instanceof Parameter and
      isArgvStyleReceiverParameter(v)
    )
    or
    (
      v instanceof Parameter and
      exists(Function f |
        f = v.getParentScope*().(Function) and
        isRubyCfunc(f)
      )
    )
  )
}

predicate guardAnalysisOnlyExclusionReason(ValueVariable v, string reason) {
  isTarget(v) and
  (
    (
      v instanceof Parameter and
      v.getName() = "self" and
      reason = "self_parameter"
    )
    or
    (
      valueLoadedFromMarkedThreadProcField(v) and
      reason = "marked_thread_proc_field"
    )
  )
}

predicate hasGuardAnalysisOnlyExclusion(ValueVariable v) {
  isTarget(v) and
  (
    (v instanceof Parameter and v.getName() = "self")
    or
    valueLoadedFromMarkedThreadProcField(v)
  )
}

predicate guardAnalysisExclusionReason(ValueVariable v, string reason) {
  targetScopeExclusionReason(v, reason)
  or
  guardAnalysisOnlyExclusionReason(v, reason)
}

/**
 * Scope for the expensive sensitivity query.
 *
 * Source-origin exclusions such as headers and macro-generated declarations are
 * inventoried, but not expanded into derive-trigger-use sensitivity witnesses.
 */
predicate isExcludedGuardAnalysisTarget(ValueVariable v) {
  hasReviewableTargetScopeExclusion(v)
  or
  hasGuardAnalysisOnlyExclusion(v)
}
