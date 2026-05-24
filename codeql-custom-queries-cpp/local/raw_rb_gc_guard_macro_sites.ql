import cpp
import semmle.code.cpp.Macro

from MacroInvocation mi, Function f
where
  mi.getMacroName() = "RB_GC_GUARD" and
  f = mi.getEnclosingFunction()
select mi, f, mi.getLocation(), mi.getUnexpandedArgument(0)
