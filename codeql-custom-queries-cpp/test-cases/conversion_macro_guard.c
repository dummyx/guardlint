#include "ruby_stubs.h"

/*
 * FilePathValue contains an internal RB_GC_GUARD assignment in CRuby. It is a
 * semantic guard for the converted path VALUE, but it is not a removable
 * explicit lifetime guard and should not appear in redundant-guard results.
 */
VALUE filepath_conversion_guard_not_redundant(VALUE recv, VALUE path) {
    (void)recv;
    FilePathValue(path);
    const char *ptr = RSTRING_PTR(path);
    return rb_str_new(ptr, 1);
}
