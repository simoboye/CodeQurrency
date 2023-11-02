/**
 * @name synchronized
 * @kind problem
 * @problem.severity critical
 * @id java/synchronized
 */

import java
import annotation
import semmle.code.java.Concurrency

predicate hasNoSyncronizedThis(Callable ca) {
  not ca.isSynchronized()
  and
  not exists(SynchronizedStmt s | ca.getBody().(SingletonBlock).getStmt() = s |
    s.getExpr().(ThisAccess).getType() = ca.getDeclaringType()
  )
  // Maybe check that the syncronized statement starts before and ends after a the write.
}

from Class c, Method m, Field f
where 
  isMethodInThreadSafeAnnotatedClass(c, m)
  and not m.hasName("<obinit>")
  and m.writes(f)
  and hasNoSyncronizedThis(m)
select m, "Writes to a field. Consider it being in a syncronized block."
