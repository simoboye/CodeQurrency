/**
 * @name Synchronized
 * @kind problem
 * @problem.severity warning
 * @id java/synchronized
 */

import java
import annotation
import semmle.code.java.Concurrency

predicate fieldAccessNotInsideStmt(Stmt s, FieldAccess fa) {
  not (s.getLocation().getStartLine() < fa.getLocation().getStartLine() and
      s.getLocation().getEndLine() > fa.getLocation().getStartLine())  
  and 
  not (s.getLocation().getStartColumn() < fa.getLocation().getStartColumn() and
      s.getLocation().getEndColumn() > fa.getLocation().getStartColumn()) 
}

predicate hasNoSynchronizedThis(Callable ca, FieldAccess fa) {
  not ca.isSynchronized()
  and
  // Method calls should be like a write -> this is the case in synchronized query. 
  (
    not exists(SynchronizedStmt s | s.getEnclosingCallable() = ca | s.getExpr().(ThisAccess).getType() = ca.getDeclaringType())
      or
    exists(SynchronizedStmt s | s.getEnclosingCallable() = ca | fieldAccessNotInsideStmt(s.getBlock(), fa))
  )
}

from Class c, Method m, FieldAccess fa
where 
  isElementInThreadSafeAnnotatedClass(c, m)
  and not m.hasName("<obinit>")
  and fa.getEnclosingCallable() = m
  and hasNoSynchronizedThis(m, fa)
select m, "Writes to a field. Consider it being in a synchronized block."
