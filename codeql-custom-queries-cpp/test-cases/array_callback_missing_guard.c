#include "ruby_stubs.h"

/* Missing guard: a borrowed array buffer is passed to a Ruby-callback API. */
VALUE array_callback_missing_guard(VALUE recv, VALUE args) {
    int argc;
    const VALUE *argv;

    argc = RARRAY_LENINT(args);
    argv = RARRAY_CONST_PTR(args);
    return rb_funcallv(recv, INT2NUM(1), argc, argv);
}
