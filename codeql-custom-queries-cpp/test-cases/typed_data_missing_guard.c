#include "ruby_stubs.h"

/* Missing guard: a typed-data pointer is used after an allocating call. */
VALUE typed_data_missing_guard(VALUE recv, VALUE obj) {
    char *ptr;
    (void)recv;

    ptr = (char *)DATA_PTR(obj);
    rb_str_new("x", 1);
    return PTR2NUM(ptr[0]);
}
