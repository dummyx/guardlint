#include "ruby_stubs.h"

#define LOCAL_DERIVE_USE_AND_GUARD(v)      \
  do {                                     \
    const char *macro_ptr = RSTRING_PTR(v); \
    VALUE macro_tmp = rb_ary_new();        \
    rb_str_new(macro_ptr, 1);              \
    RB_GC_GUARD(v);                        \
    (void)macro_tmp;                       \
  } while (0)

VALUE witness_missing_guard(VALUE input) {
    VALUE str = input;
    const char *ptr = RSTRING_PTR(str);
    VALUE tmp = rb_ary_new();
    VALUE out = rb_str_new(ptr, 1);
    (void)tmp;
    return out;
}

VALUE witness_correct_guard(VALUE input) {
    VALUE str = input;
    const char *ptr = RSTRING_PTR(str);
    VALUE tmp = rb_ary_new();
    VALUE out = rb_str_new(ptr, 1);
    RB_GC_GUARD(str);
    (void)tmp;
    return out;
}

VALUE witness_guard_before_trigger(VALUE input) {
    VALUE str = input;
    const char *ptr = RSTRING_PTR(str);
    RB_GC_GUARD(str);
    VALUE tmp = rb_ary_new();
    VALUE out = rb_str_new(ptr, 1);
    (void)tmp;
    return out;
}

VALUE witness_guard_between_trigger_and_use(VALUE input) {
    VALUE str = input;
    const char *ptr = RSTRING_PTR(str);
    VALUE tmp = rb_ary_new();
    RB_GC_GUARD(str);
    VALUE out = rb_str_new(ptr, 1);
    (void)tmp;
    return out;
}

VALUE witness_later_owner_anchor(VALUE input) {
    VALUE str = input;
    const char *ptr = RSTRING_PTR(str);
    VALUE tmp = rb_ary_new();
    VALUE out = rb_str_new(ptr, 1);
    rb_identity(str);
    (void)tmp;
    return out;
}

VALUE witness_branch_only_guard(VALUE input, int take_guarded) {
    VALUE str = input;
    const char *ptr = RSTRING_PTR(str);
    VALUE tmp = rb_ary_new();
    if (take_guarded) {
        VALUE out = rb_str_new(ptr, 1);
        RB_GC_GUARD(str);
        (void)tmp;
        return out;
    }
    else {
        VALUE out = rb_str_new(ptr, 2);
        (void)tmp;
        return out;
    }
}

VALUE witness_guarded_ptr_call(VALUE input) {
    VALUE str = input;
    const char *ptr = RSTRING_PTR(str);
    VALUE tmp = rb_ary_new();
    VALUE out = rb_str_new(ptr, 1);
    rb_gc_guarded_ptr(&(str));
    (void)tmp;
    return out;
}

VALUE witness_guarded_ptr_val_call(VALUE input) {
    VALUE str = input;
    const char *ptr = RSTRING_PTR(str);
    VALUE tmp = rb_ary_new();
    VALUE out = rb_str_new(ptr, 1);
    rb_gc_guarded_ptr_val(&(str), str);
    (void)tmp;
    return out;
}

VALUE witness_redundant_guard(VALUE input) {
    VALUE str = input;
    RB_GC_GUARD(str);
    return str;
}

VALUE witness_internal_guard_macro(VALUE input) {
    VALUE path = input;
    FilePathValue(path);
    return path;
}

VALUE witness_macro_generated_fallback(VALUE input) {
    VALUE str = input;
    LOCAL_DERIVE_USE_AND_GUARD(str);
    return str;
}
