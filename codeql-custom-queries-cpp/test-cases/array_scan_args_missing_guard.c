#include "ruby_stubs.h"

/*
 * Missing guard: an array element buffer is borrowed and passed directly to
 * rb_scan_args_kw without a later owner use. This mirrors open_key_args.
 */
VALUE array_scan_args_missing_guard(VALUE recv, VALUE args) {
    VALUE mode = 0, perm = 0, opt = 0;
    int argc;
    (void)recv;

    argc = RARRAY_LENINT(args);
    rb_scan_args_kw(RB_SCAN_ARGS_LAST_HASH_KEYWORDS, argc, RARRAY_CONST_PTR(args), "02:", &mode, &perm, &opt);
    return mode;
}
