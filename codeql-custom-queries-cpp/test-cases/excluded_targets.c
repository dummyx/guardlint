#include "ruby_stubs.h"

VALUE excluded_first_parameter_missing(VALUE obj) {
    const char *ptr = RSTRING_PTR(obj);
    VALUE tmp = rb_str_new("x", 1);
    (void)tmp;
    return rb_str_new(ptr, 1);
}

VALUE excluded_first_parameter_guarded(VALUE obj) {
    const char *ptr = RSTRING_PTR(obj);
    VALUE tmp = rb_str_new("x", 1);
    VALUE out = rb_str_new(ptr, 1);
    (void)tmp;
    RB_GC_GUARD(obj);
    return out;
}

VALUE excluded_first_parameter_no_obligation(VALUE obj) {
    return obj;
}

static VALUE excluded_ruby_cfunc_parameter(VALUE recv, VALUE str) {
    const char *ptr = RSTRING_PTR(str);
    VALUE tmp = rb_str_new("x", 1);
    (void)recv;
    (void)tmp;
    return rb_str_new(ptr, 1);
}

void Init_excluded_targets(void) {
    rb_define_method(0, "excluded_ruby_cfunc_parameter", excluded_ruby_cfunc_parameter, 1);
}

static VALUE excluded_block_callback_parameter(
    VALUE item, VALUE data, int argc, const VALUE *argv, VALUE blockarg) {
    const char *ptr = RSTRING_PTR(data);
    VALUE tmp = rb_str_new("x", 1);
    (void)item;
    (void)argc;
    (void)argv;
    (void)blockarg;
    (void)tmp;
    return rb_str_new(ptr, 1);
}

VALUE excluded_block_callback_driver(VALUE recv, VALUE ary, VALUE data) {
    const VALUE *argv = RARRAY_CONST_PTR(ary);
    (void)recv;
    return rb_block_call(ary, 0, 0, argv, excluded_block_callback_parameter, data);
}
