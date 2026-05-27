/**
 * GuardLint source-origin target configuration.
 *
 * The checked-in query pack defaults to the primary paper/reporting scope,
 * which excludes headers, generated-like included/template files, and
 * macro-expanded declarations. The reproduction runner enables the
 * `include-all` sensitivity mode by copying the query pack to a temporary
 * directory and changing this predicate to `1 = 1` in that temporary copy only.
 */
predicate includeAllSourceOriginTargets() {
  1 = 0
}
