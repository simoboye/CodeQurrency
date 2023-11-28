/**
 * @name Synchronized
 * @kind problem
 * @problem.severity warning
 * @id java/synchronized
 */

import java
import annotation
import semmle.code.java.Concurrency

predicate hasNoSynchronizedThis(Callable ca) {
  not ca.isSynchronized()
  and
  // Method calls should be like a write -> this is the case in synchronized query. 
  not exists(SynchronizedStmt s | ca.getBody().(SingletonBlock).getStmt() = s | // Only finds methods that has a synchronized block in the beginning.
    s.getExpr().(ThisAccess).getType() = ca.getDeclaringType()
  )
  // Maybe check that the synchronized statement starts before and ends after a the write.
}

from Class c, Method m, Field f
where 
  isElementInThreadSafeAnnotatedClass(c, m)
  and not m.hasName("<obinit>")
  and m.accesses(f) // Could there be a bug where we assume that the field is a field of the same class as the method. But maybe the field could be a field belonging to another class than the method?
  and hasNoSynchronizedThis(m)
select m, "Writes to a field. Consider it being in a synchronized block."
