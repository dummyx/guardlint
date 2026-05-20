#ifndef RUBY_STUBS_H
#define RUBY_STUBS_H

typedef unsigned long VALUE;

/* Pointer extractors */
static inline char *RSTRING_PTR(VALUE v) { return (char *)(void *)v; }
static inline void *RARRAY_PTR(VALUE v) { return (void *)(void *)v; }
static inline const VALUE *RARRAY_CONST_PTR(VALUE v) { return (const VALUE *)(void *)v; }
static inline void *DATA_PTR(VALUE v) { return (void *)(void *)v; }
#define RTYPEDDATA_GET_DATA(v) DATA_PTR(v)
#define Data_Get_Struct(obj, type, sval) ((sval) = (type *)DATA_PTR(obj))
#define TypedData_Get_Struct(obj, type, data_type, sval) ((sval) = (type *)DATA_PTR(obj))

/* Numeric helpers */
#define PTR2NUM(x) ((VALUE)(x))
#define INT2NUM(x) ((VALUE)(x))
#define LONG2NUM(x) ((VALUE)(x))

/* GC guard shim (keeps VALUE visible to the compiler/analysis) */
static inline volatile VALUE *rb_gc_guarded_ptr(volatile VALUE *ptr) { return ptr; }
static inline VALUE rb_gc_guarded_ptr_val(volatile VALUE *ptr, VALUE val) {
  (void)ptr;
  return val;
}
#define RB_GC_GUARD(v) (*rb_gc_guarded_ptr(&(v)))
#define FilePathValue(v) (RB_GC_GUARD(v) = rb_get_path(v))

/* Minimal constants */
#define T_SYMBOL 1
#define RB_SCAN_ARGS_LAST_HASH_KEYWORDS 1

/* Dummy definitions so cc -c succeeds */
static inline VALUE rb_str_new(const char *ptr, long len) { (void)ptr; (void)len; return 1; }
static inline VALUE rb_str_concat(VALUE a, VALUE b) { (void)a; (void)b; return a; }
static inline VALUE rb_identity(VALUE v) { return v; }
static inline VALUE rb_get_path(VALUE v) { return v; }
static inline VALUE rb_ary_new(void) { return 2; }
static inline VALUE rb_ary_push(VALUE ary, VALUE val) { (void)val; return ary; }
static inline VALUE rb_hash_new(void) { return 3; }
static inline VALUE rb_hash_aset(VALUE hash, VALUE key, VALUE val) { (void)key; (void)val; return hash; }
static inline VALUE rb_hash_aref(VALUE hash, VALUE key) { (void)hash; (void)key; return 0; }
static inline VALUE rb_profile_frame_full_label(VALUE frame) { return frame; }
static inline VALUE rb_profile_frame_absolute_path(VALUE frame) { return frame; }
static inline VALUE rb_profile_frame_first_lineno(VALUE frame) { return frame; }
static inline long RARRAY_LEN(VALUE v) { (void)v; return 1; }
static inline int RARRAY_LENINT(VALUE v) { (void)v; return 1; }
static inline VALUE rb_ary_entry(VALUE ary, long idx) { (void)ary; (void)idx; return 4; }
static inline int RB_TYPE_P(VALUE v, int type) { (void)v; (void)type; return 1; }
static inline const char *rb_id2name(VALUE id) { (void)id; return "id"; }
static inline VALUE rb_funcallv(VALUE recv, VALUE mid, int argc, const VALUE *argv) {
  (void)recv;
  (void)mid;
  (void)argc;
  (void)argv;
  return 5;
}
static inline int rb_scan_args(int argc, const VALUE *argv, const char *fmt, ...) {
  (void)argc;
  (void)argv;
  (void)fmt;
  return 0;
}
static inline int rb_scan_args_kw(int kw, int argc, const VALUE *argv, const char *fmt, ...) {
  (void)kw;
  (void)argc;
  (void)argv;
  (void)fmt;
  return 0;
}
static inline int rb_scan_args_set(int kw, int argc, const VALUE *argv, const char *fmt, ...) {
  (void)kw;
  (void)argc;
  (void)argv;
  (void)fmt;
  return 0;
}

#endif /* RUBY_STUBS_H */
