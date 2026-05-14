#include "ruby_stubs.h"

/* Safe: a visible owner VALUE use after the trigger keeps the owner live. */
VALUE owner_visible_after_trigger_stays_safe(VALUE recv, VALUE str) {
    const char *ptr;
    VALUE tmp;
    (void)recv;

    ptr = RSTRING_PTR(str);
    tmp = rb_str_new("x", 1);
    tmp = rb_identity(str);
    return PTR2NUM(ptr[0]);
}
