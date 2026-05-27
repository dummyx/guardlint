#include "ruby_stubs.h"
#include "source_origin_header_fixture.h"
#include "source_origin_inc_fixture.inc"

#define DECLARE_MACRO_OWNER(name, input) VALUE name = rb_identity(input)

VALUE source_origin_macro_decl_missing(VALUE input) {
    DECLARE_MACRO_OWNER(str, input);
    const char *ptr = RSTRING_PTR(str);
    VALUE tmp = rb_str_new("x", 1);
    (void)tmp;
    return rb_str_new(ptr, 1);
}

VALUE source_origin_driver(VALUE input) {
    VALUE a = source_origin_header_missing(input);
    VALUE b = source_origin_inc_missing(input);
    VALUE c = source_origin_macro_decl_missing(input);
    return rb_str_concat(rb_str_concat(a, b), c);
}
