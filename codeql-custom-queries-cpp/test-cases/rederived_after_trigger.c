#include "ruby_stubs.h"

/* Re-deriving the pointer after an intervening trigger should stay safe. */
VALUE rederived_after_trigger_stays_safe(VALUE recv, VALUE str) {
    (void)recv;
    const char *ptr = RSTRING_PTR(str);
    rb_ary_new();
    ptr = RSTRING_PTR(str);
    return PTR2NUM(ptr);
}
