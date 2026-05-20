#include "ruby_stubs.h"

struct rb_encoding {
    int index;
};

static const int encoding_data_type = 1;
static const int owned_data_type = 2;

/* Safe: encoding VALUEs wrap global rb_encoding storage, not object-owned bytes. */
struct rb_encoding *rb_to_encoding(VALUE encoding) {
    return (struct rb_encoding *)RTYPEDDATA_GET_DATA(encoding);
}

VALUE nonowning_typed_payload_safe(VALUE recv, VALUE encoding) {
    struct rb_encoding *enc = rb_to_encoding(encoding);
    (void)recv;

    rb_str_new("x", 1);
    return PTR2NUM(enc);
}

/* Missing: ordinary typed-data payload remains object-owned subordinate storage. */
VALUE owned_typed_payload_missing(VALUE recv, VALUE obj) {
    char *ptr;
    (void)recv;

    TypedData_Get_Struct(obj, char, &owned_data_type, ptr);
    rb_str_new("x", 1);
    return PTR2NUM(ptr[0]);
}

/* Safe: after the trigger, stale pointers are used only for a scalar offset. */
VALUE pointer_diff_only_safe(VALUE recv, VALUE str) {
    const char *start = RSTRING_PTR(str);
    const char *end = start + 3;
    (void)recv;

    rb_str_new("x", 1);
    return LONG2NUM(end - start);
}

/* Missing: a real dereference after the trigger is still a vulnerable use. */
VALUE pointer_deref_after_trigger_missing(VALUE recv, VALUE str) {
    const char *start = RSTRING_PTR(str);
    (void)recv;

    rb_str_new("x", 1);
    return PTR2NUM(start[0]);
}
