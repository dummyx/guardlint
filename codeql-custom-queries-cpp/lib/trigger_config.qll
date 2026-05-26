/**
 * GuardLint trigger-mode configuration.
 *
 * The checked-in query pack defaults to the heuristic trigger model. The
 * reproduction runner enables the conservative recursive-gc-enter model by
 * copying the query pack to a temporary directory and changing this predicate
 * to `1 = 1` in that temporary copy only.
 */
predicate useRecursiveGcEnterTriggers() {
  1 = 0
}
