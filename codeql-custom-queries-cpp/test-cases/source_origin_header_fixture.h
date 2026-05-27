#ifndef SOURCE_ORIGIN_HEADER_FIXTURE_H
#define SOURCE_ORIGIN_HEADER_FIXTURE_H

#include "ruby_stubs.h"

static inline VALUE source_origin_header_missing(VALUE input) {
    VALUE str = rb_identity(input);
    const char *ptr = RSTRING_PTR(str);
    VALUE tmp = rb_str_new("x", 1);
    (void)tmp;
    return rb_str_new(ptr, 1);
}

#endif /* SOURCE_ORIGIN_HEADER_FIXTURE_H */
