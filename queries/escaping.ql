/**
 * @name Escaping
 * @kind problem
 * @problem.severity error
 * @id java/escaping
 */

import java
import annotation

predicate isPrivate(FieldAccess fa) {
  fa.getField().isPrivate()
}

predicate isReferencedOutsideLock(FieldAccess fa, MethodAccess ma) {
  // limitation: this will not field accesses that is not thread safe if there is not a lock present
  // it does also not take into account unlock.
  // limitation: can not see if a method is syncronized
  // limitation: syncronized
  // isPrivate(f) and We think that we will report this twice if it is public
  ma.getMethod().hasName("lock")
  and not fa.getSite().toString() = "<obinit>"
  and not fa.getSite().getDeclaringType().toString() = fa.getSite().toString()
  and fa.getSite() = ma.getEnclosingCallable()
  and fa.getLocation().getStartLine() < ma.getLocation().getStartLine()
  
}

predicate isEscaping(FieldAccess fa, MethodAccess ma) {
  not isPrivate(fa)
  and isReferencedOutsideLock(fa, ma)
}

from FieldWrite fa, MethodAccess ma, Class c
where isFieldInThreadSafeAnnotatedClass(c, fa.getField()) 
  and isEscaping(fa, ma)
select fa, "Potentially escaping field"
