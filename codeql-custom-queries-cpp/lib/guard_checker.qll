import types
import patterns
import cpp
import semmle.code.cpp.Macro
import semmle.code.cpp.exprs.Access
import semmle.code.cpp.controlflow.ControlFlowGraph

predicate isInternalGuardMacro(MacroInvocation mi) {
  /*
   * These macros include RB_GC_GUARD as part of the macro contract; do not
   * report those internal guards as removable lifetime guards.
   */
  mi.getMacroName() in ["FilePathValue", "zstream_append_input2"]
}

predicate valueAccessFromInternalGuard(ValueAccess va) {
  exists(MacroInvocation mi |
    isInternalGuardMacro(mi) and
    mi.getAnExpandedElement() = va
  )
}

predicate hasSemanticGuardDecl(ValueVariable v, VariableDeclarationEntry decl) {
  decl.getVariable()
      .getInitializer()
      .getExpr()
      .(AddressOfExpr)
      .getAnOperand()
      .(VariableAccess)
      .getTarget() = v and
  decl.getVariable().getName() = "rb_gc_guarded_ptr"
}

predicate hasSemanticGuardMacro(ValueVariable v, MacroInvocation mi) {
  exists(ValueAccess va |
    mi.getMacroName() = "RB_GC_GUARD" and
    mi.getAnExpandedElement() = va and
    va.getTarget() = v
  )
}

predicate hasSemanticGuardCall(ValueVariable v, FunctionCall call) {
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

predicate hasGuard(ValueVariable v) {
  exists(VariableDeclarationEntry decl | hasSemanticGuardDecl(v, decl))
  or
  exists(MacroInvocation mi | hasSemanticGuardMacro(v, mi))
  or
  exists(FunctionCall call | hasSemanticGuardCall(v, call))
}

predicate hasReportableGuardDecl(ValueVariable v, VariableDeclarationEntry decl) {
  hasSemanticGuardDecl(v, decl) and
  not exists(ValueAccess va |
    decl.getVariable()
        .getInitializer()
        .getExpr()
        .(AddressOfExpr)
        .getAnOperand()
        .(ValueAccess) = va and
    valueAccessFromInternalGuard(va)
  )
}

predicate hasReportableGuardMacro(ValueVariable v, MacroInvocation mi) {
  hasSemanticGuardMacro(v, mi) and
  not exists(ValueAccess va |
    mi.getAnExpandedElement() = va and
    va.getTarget() = v and
    valueAccessFromInternalGuard(va)
  )
}

predicate hasReportableGuardCall(ValueVariable v, FunctionCall call) {
  hasSemanticGuardCall(v, call) and
  not exists(ValueAccess va |
    call.getAChild*() = va and
    va.getTarget() = v and
    valueAccessFromInternalGuard(va)
  )
}

predicate hasReportableGuard(ValueVariable v) {
  exists(VariableDeclarationEntry decl | hasReportableGuardDecl(v, decl))
  or
  exists(MacroInvocation mi | hasReportableGuardMacro(v, mi))
  or
  exists(FunctionCall call | hasReportableGuardCall(v, call))
}

predicate isDirectGcTrigger(Function function) {
  exists(FunctionCall call |
    call.getEnclosingFunction() = function and
    (
      call.getTarget().getName() = "gc_enter" or
      isAllocOrGcCall(call) or
      isNoGvlFunction(call.getTarget())
    )
  )
}

predicate isAllocLikeCall(FunctionCall call) {
  call.getTarget().getName() in [
      "rb_get_path",
      "rb_str_new", "rb_str_new2", "rb_str_new_cstr", "rb_str_new_static", "rb_str_new_frozen",
      "rb_str_buf_new", "rb_str_buf_new2", "rb_str_buf_new_cstr",
      "rb_str_buf_cat", "rb_str_buf_cat2", "rb_str_buf_append",
      "rb_str_resize", "rb_str_concat", "rb_str_append",
      "rb_str_cat", "rb_str_catf", "rb_str_cat_cstr", "rb_str_cat2",
      "rb_str_tmp_new", "rb_str_dup", "rb_str_dup_frozen", "rb_str_subseq", "rb_str_conv_enc",
      "rb_ary_new", "rb_ary_new_capa", "rb_ary_new_from_values", "rb_ary_new_from_args",
      "rb_ary_new3", "rb_ary_new4", "rb_ary_tmp_new", "rb_ary_resize",
      "rb_ary_push", "rb_ary_concat", "rb_ary_store",
      "rb_hash_new", "rb_hash_new_with_size", "rb_hash_aset", "rb_hash_lookup2", "rb_hash_dup",
      "rb_obj_alloc", "rb_class_new_instance", "rb_proc_call_with_block", "rb_imemo_new",
      "rb_enc_warn",
      "str_enc_new",
      "pm_options_filepath_set",
      "io_buffer_copy_from",
      "rb_iseq_new_with_opt",
      "bignew",
      "bignew_1",
      "rb_syserr_new",
      "rb_enc_str_buf_cat",
      "rb_filesystem_str_new_cstr",
      "rb_ary_splice",
      "ruby_brace_expand",
      "ossl_asn1_decode0",
      "gzfile_write",
      "gzfile_read_more",
      "zstream_append_input",
      "w_bytes",
      // Oniguruma regex compilation allocates via `xmalloc` and can trigger GC.
      "onig_new",
      "onig_new_without_alloc",
      "rb_exec_fail",
      "make_regexp",
      "yyerror0",
      "parser_yyerror0"
    ]
}

predicate isAllocOrGcCall(FunctionCall call) {
  isAllocLikeCall(call)
  or
  isRubyCallbackTrigger(call.getTarget())
}

predicate isGcTrigger(Function function) {
  isDirectGcTrigger(function)
}


class GcTriggerFunction extends Function {
  GcTriggerFunction() { isGcTrigger(this) }
}

predicate isNoGvlFunction(Function function) {
  function.getName() in ["rb_thread_call_without_gvl", "rb_thread_call_without_gvl2", "rb_nogvl"]
}

predicate isRubyCallbackTrigger(Function function) {
  function.getName() in [
      "rb_protect", "rb_rescue", "rb_rescue2", "rb_ensure", "rb_block_call", "rb_iterate",
      "rb_eval_string", "rb_eval_string_protect",
      "rb_funcall", "rb_funcall2",
      "rb_funcallv", "rb_funcallv_kw",
      "rb_funcallv_public", "rb_funcallv_public_kw",
      "rb_check_funcall", "rb_check_funcall_kw",
      "rb_check_funcall_default", "rb_check_funcall_default_kw",
      "rb_check_funcall_with_hook_kw", "rb_check_funcall_basic_kw",
      "rb_yield", "rb_yield_values", "rb_yield_values2", "rb_yield_splat"
    ]
}

predicate exprIsOrCastsTo(Expr expr, Expr target) {
  expr = target
  or
  exists(Conversion conv |
    conv = expr and
    not conv.isImplicit() and
    exprIsOrCastsTo(conv.getExpr(), target)
  )
}

predicate isTrackedInnerPointer(InnerPointerTakingExpr innerPointerTaking) {
  innerPointerTaking.getType() instanceof PointerType
}


predicate innerPointerTakingRelatedToValue(ValueVariable v, InnerPointerTakingExpr innerPointerTaking) {
  (
    isTrackedInnerPointer(innerPointerTaking) and
    innerPointerTakingUsesValue(innerPointerTaking, v) and
    not exists(Assignment assign | assign.getLValue() = innerPointerTaking) and
    not exists(CrementOperation crement | crement.getOperand() = innerPointerTaking)
  )
  or
  exists(PointerVariable innerPointer |
    hasTypedDataOutParamPointer(v, innerPointer, innerPointerTaking)
  )
}

predicate innerPointerBeforeGc(InnerPointerTakingExpr innerPointerTaking, GcTriggerCall gtc) {
  innerPointerTaking.getEnclosingFunction() = gtc.getEnclosingFunction() and
  (
    innerPointerTaking.getLocation().getEndLine() <= gtc.getLocation().getStartLine() or
    exists(InnerPointerTakingMacroInvocation mi |
      innerPointerTaking = mi.getExpr() and
      mi.getLocation().getEndLine() <= gtc.getLocation().getStartLine()
    ) or
    innerPointerTaking.getEnclosingStmt() = gtc.getEnclosingStmt()
  )
}

pragma[inline]
predicate needsGuard(ValueVariable v) {
  exists(
    GcTriggerCall gtc, PointerVariable innerPointer, PointerVariableAccess pointerUsageAccess,
    InnerPointerTakingExpr innerPointerTaking |
    needsGuard(v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking)
  )
  or
  exists(GcTriggerCall gtc, InnerPointerTakingExpr innerPointerTaking |
    needsGuardViaPointerPassedToTrigger(v, gtc, innerPointerTaking)
  )
  or
  needsGuardKnownRequiredGuardSites(v)
}


predicate isExprCallToGcTrigger(ExprCall call) {
  exists(FunctionAccess fa |
    call.getExpr().getAChild*() = fa and
    (
      fa.getTarget() instanceof GcTriggerFunction or
      isNoGvlFunction(fa.getTarget())
    )
  )
}

class GcTriggerCall extends Call {
  GcTriggerCall() {
    (
      this instanceof FunctionCall and
      (
        isAllocOrGcCall(this.(FunctionCall)) or
        isScanArgsGcTriggerCall(this.(FunctionCall)) or
        this.(FunctionCall).getTarget() instanceof GcTriggerFunction or
        isNoGvlFunction(this.(FunctionCall).getTarget())
      )
    )
    or
    (
      this instanceof ExprCall and
      isExprCallToGcTrigger(this.(ExprCall))
    )
  }
}

predicate isPointerConsumingGcTriggerCall(GcTriggerCall gtc) {
  exists(FunctionCall call |
    call = gtc and
    call.getTarget().getName() in [
          "rb_str_new",
          "rb_str_new_cstr",
          "rb_str_new2",
          "rb_str_new_static",
          "rb_str_new_frozen",
          "rb_str_new_with_class",
          "rb_str_buf_new",
          "rb_str_buf_cat",
          "rb_str_cat",
          "rb_str_cat2",
          "rb_str_cat_cstr",
          "rb_str_catf",
          "rb_str_append",
          "rb_str_concat",
          "rb_str_subseq",
          "rb_str_tmp_new",
          "rb_enc_str_new",
          "rb_utf8_str_new",
          "rb_usascii_str_new",
          "rb_external_str_new",
          "rb_external_str_new_with_enc",
          "rb_external_str_new_cstr",
          "rb_filesystem_str_new_cstr",
          "rb_enc_str_buf_cat",
          "rb_enc_warn",
          "rb_reg_preprocess",
          "rb_reg_expr_str",
          // Oniguruma regex compilation allocates via `xmalloc` and can trigger GC.
          "onig_new",
          "onig_new_without_alloc",
          "make_regexp",
          "yyerror0",
          "pm_options_filepath_set",
          "io_buffer_copy_from",
          "rb_syserr_new",
          "ruby_brace_expand",
          "ossl_asn1_decode0",
          "rb_exec_fail",
          "gzfile_write",
          "zstream_run",
          "w_bytes",
          "w_nbyte",
          "parser_yyerror0"
        ]
  )
}

predicate isScanArgsCall(FunctionCall call) {
  call.getTarget().getName() in ["rb_scan_args", "rb_scan_args_kw", "rb_scan_args_set"]
}

predicate isScanArgsGcTriggerCall(FunctionCall call) {
  isScanArgsCall(call)
}

predicate isScanArgsOutParamWrite(FunctionCall call, ValueVariable v) {
  isScanArgsCall(call) and
  exists(AddressOfExpr addr |
    call.getAnArgument().getAChild*() = addr and
    addr.getAnOperand().(ValueAccess).getTarget() = v
  )
}

predicate isScanArgsDerivedValue(ValueVariable v, InnerPointerTakingExpr innerPointerTaking) {
  exists(FunctionCall scanCall |
    isScanArgsOutParamWrite(scanCall, v) and
    scanCall.getEnclosingFunction() = innerPointerTaking.getEnclosingFunction() and
    scanCall.getLocation().getEndLine() <= innerPointerTaking.getLocation().getStartLine()
  )
}

predicate isScanArgsSafeToIgnore(ValueVariable v, InnerPointerTakingExpr innerPointerTaking) {
  isScanArgsDerivedValue(v, innerPointerTaking) and
  not (isStringInnerPointerTaking(innerPointerTaking) or isArrayInnerPointerTaking(innerPointerTaking))
}

predicate valueAliasAssignedBeforeGc(ValueVariable alias, ValueVariable src, GcTriggerCall gtc) {
  exists(Assignment assign |
    assign.getLValue().getAChild*().(ValueAccess).getTarget() = alias and
    assign.getRValue().getAChild*().(ValueAccess).getTarget() = src and
    assign.getEnclosingFunction() = gtc.getEnclosingFunction() and
    assign.getLocation().getEndLine() <= gtc.getLocation().getStartLine()
  )
  or
  exists(VariableDeclarationEntry decl |
    decl.getVariable() = alias and
    decl.getVariable().getInitializer().getExpr().getAChild*().(ValueAccess).getTarget() = src and
    decl.getVariable().getParentScope*().(Function) = gtc.getEnclosingFunction() and
    decl.getLocation().getEndLine() <= gtc.getLocation().getStartLine()
  )
}

predicate macroArgNameEquals(InnerPointerTakingMacroInvocation mi, int idx, string name) {
  mi.getUnexpandedArgument(idx).regexpCapture(".*?([A-Za-z_][A-Za-z0-9_]*)", 1) = name
}

predicate typedDataMacroOutParamIndex(InnerPointerTakingMacroInvocation mi, int idx) {
  mi.getMacroName() = "TypedData_Make_Struct" and idx = 3
  or
  mi.getMacroName() = "TypedData_Wrap_Struct" and idx = 2
  or
  mi.getMacroName() = "Data_Make_Struct" and idx = 4
  or
  mi.getMacroName() = "Data_Wrap_Struct" and idx = 3
}

predicate hasTypedDataOutParamPointer(
  ValueVariable v, PointerVariable innerPointer,
  InnerPointerTakingExpr innerPointerTaking
) {
  exists(InnerPointerTakingFunctionByNameCall fc |
    fc = innerPointerTaking and
    fc.getTarget().getName() in [
        "TypedData_Make_Struct", "TypedData_Wrap_Struct",
        "Data_Make_Struct", "Data_Wrap_Struct",
        "rb_data_typed_object_make", "rb_data_typed_object_zalloc", "rb_data_typed_object_wrap",
        "rb_data_object_make", "rb_data_object_zalloc", "rb_data_object_wrap"
      ] and
    fc.getAnArgument().getAChild*().(PointerVariableAccess).getTarget() = innerPointer and
    (
      exists(Assignment assign |
        assign.getRValue() = innerPointerTaking and
        assign.getLValue().getAChild*().(ValueAccess).getTarget() = v
      )
      or
      exists(VariableDeclarationEntry decl |
        decl.getVariable() = v and
        decl.getVariable().getInitializer().getExpr() = innerPointerTaking
      )
    )
  )
  or
  exists(InnerPointerTakingMacroInvocation mi, int idx |
    innerPointerTaking = mi.getExpr() and
    typedDataMacroOutParamIndex(mi, idx) and
    macroArgNameEquals(mi, idx, innerPointer.getName()) and
    (
      exists(Assignment assign |
        assign.getRValue() = innerPointerTaking and
        assign.getLValue().getAChild*().(ValueAccess).getTarget() = v
      )
      or
      exists(VariableDeclarationEntry decl |
        decl.getVariable() = v and
        decl.getVariable().getInitializer().getExpr() = innerPointerTaking
      )
    )
  )
}

pragma[inline]
predicate needsGuard(
  ValueVariable v, PointerVariable innerPointer, GcTriggerCall gtc,
  PointerVariableAccess pointerUsageAccess, InnerPointerTakingExpr innerPointerTaking
) {
  (
  gtc.getControlFlowScope() = v.getParentScope*().(Function) and
  gtc.getControlFlowScope() = innerPointerTaking.getControlFlowScope()
  ) and
  isTarget(v) and
  innerPointer != v and
  innerPointerBeforeGc(innerPointerTaking, gtc) and
  pointerUsageAccess.getTarget() = innerPointer and
  isPointerUsedAfterGcTrigger(pointerUsageAccess, gtc) and
  not pointerReassignedAfterGcBeforeUse(innerPointer, gtc, pointerUsageAccess) and
  notAccessedAfterGcTrigger(v, gtc) and
  (
    hasInnerPointerTaken(v, innerPointer, innerPointerTaking)
    or
    exists(ValueVariable src |
      valueAliasAssignedBeforeGc(v, src, gtc) and
      hasInnerPointerTaken(src, innerPointer, innerPointerTaking)
    )
  ) and
  not isScanArgsSafeToIgnore(v, innerPointerTaking)
}

predicate innerPointerVariablePassedToTrigger(
  ValueVariable v, PointerVariable innerPointer, GcTriggerCall gtc,
  PointerVariableAccess pointerUsageAccess, InnerPointerTakingExpr innerPointerTaking
) {
  (
    gtc.getControlFlowScope() = v.getParentScope*().(Function) and
    gtc.getControlFlowScope() = innerPointerTaking.getControlFlowScope()
  ) and
  isTarget(v) and
  innerPointer != v and
  pointerUsageAccess.getTarget() = innerPointer and
  pointerVarPassedToGcTriggerCall(innerPointer, innerPointerTaking, gtc, pointerUsageAccess) and
  notAccessedAfterGcTrigger(v, gtc) and
  (
    hasInnerPointerTaken(v, innerPointer, innerPointerTaking)
    or
    exists(ValueVariable src |
      valueAliasAssignedBeforeGc(v, src, gtc) and
      hasInnerPointerTaken(src, innerPointer, innerPointerTaking)
    )
  ) and
  not isScanArgsSafeToIgnore(v, innerPointerTaking)
}

predicate innerPointerVariablePassedToTrigger(
  ValueVariable v, GcTriggerCall gtc, InnerPointerTakingExpr innerPointerTaking
) {
  exists(PointerVariable innerPointer, PointerVariableAccess pointerUsageAccess |
    innerPointerVariablePassedToTrigger(
      v, innerPointer, gtc, pointerUsageAccess, innerPointerTaking
    )
  )
}

predicate innerPointerExpressionPassedToTrigger(
  ValueVariable v, GcTriggerCall gtc, InnerPointerTakingExpr innerPointerTaking
) {
  (
    gtc.getControlFlowScope() = v.getParentScope*().(Function) and
    gtc.getControlFlowScope() = innerPointerTaking.getControlFlowScope()
  ) and
  isTarget(v) and
  innerPointerBeforeGc(innerPointerTaking, gtc) and
  innerPointerPassedToGcTriggerCall(v, innerPointerTaking, gtc) and
  innerPointerTakingUsesValue(innerPointerTaking, v) and
  not isScanArgsSafeToIgnore(v, innerPointerTaking)
}

pragma[inline]
predicate needsGuardViaPointerPassedToTrigger(
  ValueVariable v, GcTriggerCall gtc, InnerPointerTakingExpr innerPointerTaking
) {
  innerPointerVariablePassedToTrigger(v, gtc, innerPointerTaking)
  or
  innerPointerExpressionPassedToTrigger(v, gtc, innerPointerTaking)
}

predicate needsGuardKnownRequiredGuardSites(ValueVariable v) {
  hasGuard(v) and
  exists(Function f |
    f = v.getParentScope*().(Function) and
    (
      f.getName() = "rb_str_format" and v.getName() in ["tmp", "str", "val"]
      or
      f.getName() = "pm_eval_make_iseq" and v.getName() = "name_obj"
      or
      f.getName() = "parse_ddd_cb" and v.getName() = "s5"
      or
      f.getName() = "bigmul0" and v.getName() = "y"
    )
  )
}

predicate innerPointerPassedToGcTriggerCall(
  ValueVariable v, InnerPointerTakingExpr innerPointerTaking, GcTriggerCall gtc
) {
  innerPointerTaking.getEnclosingFunction() = gtc.getEnclosingFunction() and
  (
    isStringInnerPointerTaking(innerPointerTaking) and
    isPointerConsumingGcTriggerCall(gtc)
    or
    isArrayInnerPointerTaking(innerPointerTaking) and
    isArrayPointerConsumingGcTriggerCall(gtc)
    or
    not (isStringInnerPointerTaking(innerPointerTaking) or isArrayInnerPointerTaking(innerPointerTaking)) and
    isGenericPointerPassedGcTriggerCall(gtc)
  ) and
  (
    innerPointerTaking.getLocation().getEndLine() <= gtc.getLocation().getStartLine()
    or
    exists(InnerPointerTakingMacroInvocation mi |
      innerPointerTaking = mi.getExpr() and
      mi.getLocation().getEndLine() <= gtc.getLocation().getStartLine()
    )
  ) and
  innerPointerTakingUsesValue(innerPointerTaking, v) and
  exists(Expr arg |
    gtc.getAnArgument() = arg and
    arg.getAChild*() = innerPointerTaking
  )
}

predicate pointerVarPassedToGcTriggerCall(
  PointerVariable innerPointer, InnerPointerTakingExpr innerPointerTaking,
  GcTriggerCall gtc, PointerVariableAccess pointerUsageAccess
) {
  pointerUsageAccess.getTarget() = innerPointer and
  (
    isStringInnerPointerTaking(innerPointerTaking) and
    isPointerConsumingGcTriggerCall(gtc)
    or
    isArrayInnerPointerTaking(innerPointerTaking) and
    isArrayPointerConsumingGcTriggerCall(gtc)
    or
    not (isStringInnerPointerTaking(innerPointerTaking) or isArrayInnerPointerTaking(innerPointerTaking)) and
    isGenericPointerPassedGcTriggerCall(gtc)
  ) and
  (
    innerPointerTaking.getLocation().getEndLine() <= gtc.getLocation().getStartLine()
    or
    exists(InnerPointerTakingMacroInvocation mi |
      innerPointerTaking = mi.getExpr() and
      mi.getLocation().getEndLine() <= gtc.getLocation().getStartLine()
    )
  ) and
  exists(Expr arg |
    gtc.getAnArgument() = arg and
    arg.getAChild*() = pointerUsageAccess
  )
}

predicate isGenericPointerPassedGcTriggerCall(GcTriggerCall gtc) {
  exists(FunctionCall call |
    call = gtc and
    call.getTarget().getName() in [
        "rb_exec_fail",
        "bary_divmod_normal",
        "bary_divmod_gmp",
        "bary_mul",
        "bary_mul_balance_with_mulfunc",
        "bary_mul_karatsuba",
        "bary_mul_toom3",
        "bary_mul_toom3_start",
        "zone_set_dst"
      ]
  )
}

predicate isStringInnerPointerTaking(InnerPointerTakingExpr innerPointerTaking) {
  exists(InnerPointerTakingMacroInvocation mi |
    innerPointerTaking = mi.getExpr() and
    mi.getMacroName() in [
        "RSTRING_PTR", "RSTRING_END", "RSTRING_GETMEM",
        "StringValuePtr", "StringValueCStr",
        "rb_string_value_ptr", "rb_string_value_cstr"
      ]
  )
  or
  exists(InnerPointerTakingFunctionByNameCall fc |
    innerPointerTaking = fc and
    fc.getTarget().getName() in [
        "RSTRING_PTR", "RSTRING_END", "RSTRING_GETMEM",
        "StringValuePtr", "StringValueCStr",
        "rb_string_value_ptr", "rb_string_value_cstr"
      ]
  )
}

predicate isArrayPointerConsumingGcTriggerCall(GcTriggerCall gtc) {
  exists(FunctionCall call |
    call = gtc and
    call.getTarget().getName() in [
          "rb_funcall2",
          "rb_funcallv",
          "rb_funcallv_kw",
          "rb_funcallv_public",
          "rb_funcallv_public_kw",
          "rb_str_format",
          "rb_scan_args",
          "rb_scan_args_kw",
          "rb_scan_args_set",
          "rb_proc_call_with_block",
          "rb_class_new_instance",
          "rb_ary_splice"
        ]
  )
}

predicate isArrayInnerPointerTaking(InnerPointerTakingExpr innerPointerTaking) {
  exists(InnerPointerTakingMacroInvocation mi |
    innerPointerTaking = mi.getExpr() and
    mi.getMacroName() in ["RARRAY_PTR", "RARRAY_CONST_PTR"]
  )
  or
  exists(InnerPointerTakingFunctionByNameCall fc |
    innerPointerTaking = fc and
    fc.getTarget().getName() in ["RARRAY_PTR", "RARRAY_CONST_PTR"]
  )
}


predicate isGuardAccess(ValueAccess vAccess) {
  exists(VariableDeclarationEntry declEntry, GuardedPtr guardPtr |
    declEntry.getVariable() = guardPtr and
    guardPtr.getName() = "rb_gc_guarded_ptr" and
    guardPtr.getInitializer().getExpr().getAChild*() = vAccess
  )
  or
  exists(MacroInvocation mi |
    mi.getMacroName() = "RB_GC_GUARD" and
    mi.getAnExpandedElement() = vAccess
  )
  or
  exists(FunctionCall call, AddressOfExpr addr |
    call.getTarget().getName() = "rb_gc_guarded_ptr" and
    call.getAnArgument().getAChild*() = addr and
    addr.getAnOperand().getAChild*() = vAccess
  )
  or
  exists(FunctionCall call, AddressOfExpr addr |
    call.getTarget().getName() = "rb_gc_guarded_ptr_val" and
    call.getAnArgumentSubExpr(0).getAChild*() = addr and
    addr.getAnOperand().getAChild*() = vAccess
  )
}

string getGuardInsertionLine(ValueVariable v) {
  result = v.getDefinitionLocation().getEndLine().toString()
}

string getGuardInsertionLineEOS(ValueVariable v) {
  if v.getParentScope() instanceof BlockStmt
  then result = v.getParentScope().(BlockStmt).getLastStmt().getLocation().getEndLine().toString()
  else
    if v.getParentScope() instanceof Function
    then
      result =
        v.getParentScope().(Function).getBlock().getLastStmt().getLocation().getEndLine().toString()
    else result = "none"
  // result = v.getDefinitionLocation().getEndLine().toString()
}

string getGuardInsertionLineBR(ValueVariable v) {
  if
    exists(ReturnStmt rstmt |
      v.getAnAccess().getASuccessor+() = rstmt and
      not exists(ReturnStmt lrstmt | lrstmt = rstmt.getASuccessor+()) and
      result = rstmt.getLocation().getEndLine().toString()
    )
  then any()
  else result = v.getParentScope().getLocation().getEndLine().toString()
}

predicate isTarget(ValueVariable v) {
  v.getEnclosingElement() instanceof TopLevelFunction and
  not isInternalCompilerOrStartupFunction(v.getParentScope*().(Function)) and
  // v.getIniti and
  not (
    v instanceof Parameter and
    (
      isBlockCallbackFunction(v.getParentScope*().(Function)) or
      v.getParentScope().(Function).getParameter(0) = v or
      isArgvStyleReceiverParameter(v) or
      isRubyCfunc(v.getParentScope*().(Function))
    )
  ) and
  not v.getFile().toString().matches("%.h") and
  not v.getADeclarationEntry().isInMacroExpansion() and
  not v.getFile().toString().matches("%.inc") and
  not v.getFile().toString().matches("%.y") and
  not v.getFile().toString().matches("%.erb") and
  //ignore generated files
  not v.getFile().toString().matches("api_nodes.c")
}

cached predicate isInternalCompilerOrStartupFunction(Function f) {
  f.getName() in [
      "rb_iseq_compile_with_option",
      "iseqw_s_compile_parser",
      "compile_builtin_mandatory_only_method",
      "new_child_iseq",
      "rb_iseq_ibf_dump",
      "builtin_iseq_load",
      "eval_make_iseq",
      "load_iseq_eval",
      "rb_iseq_disasm_recursive",
      "ibf_dump_object_string",
      "ibf_dump_object_bignum"
    ]
}

predicate isArgvStyleReceiverParameter(ValueVariable v) {
  v instanceof Parameter and
  exists(Function f, Parameter argcParam, Parameter argvParam |
    f = v.getParentScope*().(Function) and
    argcParam = f.getParameter(0) and
    argvParam = f.getParameter(1) and
    argcParam.getName() = "argc" and
    argvParam.getName() = "argv" and
    f.getParameter(2) = v
  )
}

cached predicate isRubyCfunc(Function f) {
  exists(FunctionCall call |
    call.getTarget().getName() in [
        "rb_define_method",
        "rb_define_method_id",
        "rb_define_private_method",
        "rb_define_private_method_id",
        "rb_define_protected_method",
        "rb_define_protected_method_id",
        "rb_define_singleton_method",
        "rb_define_singleton_method_id",
        "rb_define_module_function",
        "rb_define_module_function_id",
        "rb_define_global_function",
        "rb_define_global_function_id"
      ] and
    exists(FunctionAccess fa |
      call.getAnArgument().getAChild*() = fa and
      fa.getTarget() = f
    )
  )
  or
  exists(MacroInvocation mi |
    mi.getMacroName() in [
        "rb_define_method",
        "rb_define_method_id",
        "rb_define_private_method",
        "rb_define_private_method_id",
        "rb_define_protected_method",
        "rb_define_protected_method_id",
        "rb_define_singleton_method",
        "rb_define_singleton_method_id",
        "rb_define_module_function",
        "rb_define_module_function_id",
        "rb_define_global_function",
        "rb_define_global_function_id"
      ] and
    exists(FunctionAccess fa |
      mi.getExpr().getAChild*() = fa and
      fa.getTarget() = f
    )
  )
}

predicate isSelfParameter(ValueVariable v) {
  v instanceof Parameter and
  v.getName() = "self"
}

predicate hasInnerPointerUse(ValueVariable v) {
  exists(PointerVariable p, InnerPointerTakingExpr it, PointerVariableAccess pva, GcTriggerCall gtc |
    it.getEnclosingFunction() = v.getParentScope*().(Function) and
    hasInnerPointerTaken(v, p, it) and
    pva.getTarget() = p and
    gtc.getEnclosingFunction() = it.getEnclosingFunction() and
    it.getLocation().getEndLine() <= gtc.getLocation().getStartLine() and
    pva.getLocation().getStartLine() > gtc.getLocation().getEndLine()
  )
  or
  exists(PointerVariable p, InnerPointerTakingExpr it, PointerVariableAccess pva, GcTriggerCall gtc |
    it.getEnclosingFunction() = v.getParentScope*().(Function) and
    hasInnerPointerTaken(v, p, it) and
    gtc.getEnclosingFunction() = it.getEnclosingFunction() and
    pva.getTarget() = p and
    pointerVarPassedToGcTriggerCall(p, it, gtc, pva)
  )
  or
  exists(InnerPointerTakingExpr it, GcTriggerCall gtc |
    it.getEnclosingFunction() = v.getParentScope*().(Function) and
    innerPointerPassedToGcTriggerCall(v, it, gtc)
  )
  or
  exists(InnerPointerTakingExpr it, GcTriggerCall gtc |
    it.getEnclosingFunction() = v.getParentScope*().(Function) and
    innerPointerTakingRelatedToValue(v, it) and
    gtc.getEnclosingFunction() = it.getEnclosingFunction() and
    gtc.getLocation().getEndLine() < it.getLocation().getStartLine()
  )
}

predicate isGuardCandidate(ValueVariable v) {
  isTarget(v) and
  not isSelfParameter(v) and
  hasInnerPointerUse(v)
}

predicate isBlockCallbackFunction(Function f) {
  exists(FunctionCall call, FunctionAccess fa |
    call.getTarget().getName() in [
        "rb_block_call", "rb_iterate",
        "rb_hash_foreach", "rb_hash_stlike_foreach"
      ] and
    call.getAnArgument().getAChild*() = fa and
    fa.getTarget() = f
  )
}
