static VALUE source_origin_inc_missing(VALUE input) {
    VALUE str = rb_identity(input);
    const char *ptr = RSTRING_PTR(str);
    VALUE tmp = rb_str_new("x", 1);
    (void)tmp;
    return rb_str_new(ptr, 1);
}
