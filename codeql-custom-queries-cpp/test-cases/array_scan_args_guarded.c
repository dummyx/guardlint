#include "ruby_stubs.h"

/* Guarded form of the rb_scan_args_kw borrowed-array consumer pattern. */
VALUE array_scan_args_guarded(VALUE recv, VALUE args) {
    VALUE mode = 0, perm = 0, opt = 0;
    int argc;
    (void)recv;

    argc = RARRAY_LENINT(args);
    rb_scan_args_kw(RB_SCAN_ARGS_LAST_HASH_KEYWORDS, argc, RARRAY_CONST_PTR(args), "02:", &mode, &perm, &opt);
    RB_GC_GUARD(args);
    return mode;
}
