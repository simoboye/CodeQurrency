/**
 * @name Synchronized
 * @kind problem
 * @problem.severity warning
 * @id java/synchronized
 */

import java
import annotation
import semmle.code.java.Concurrency

// predicate fieldAccessNotInsideStmt(Location stmtLocation, FieldAccess fa) {
//   not (stmtLocation.getStartLine() < fa.getLocation().getStartLine() and
//       stmtLocation.getEndLine() > fa.getLocation().getStartLine())  
//     and 
//   not (stmtLocation.getStartColumn() < fa.getLocation().getStartColumn() and
//     stmtLocation.getEndColumn() > fa.getLocation().getStartColumn()) 
// }

// predicate hasNoSynchronizedThis(Callable ca, FieldAccess fa) {
//   not ca.isSynchronized()
//   and
//   // Method calls should be like a write -> this is the case in synchronized query. 
//   (
//     not exists(SynchronizedStmt s | s.getEnclosingCallable() = ca | s.getExpr().(ThisAccess).getType() = ca.getDeclaringType())
//       or
//     exists(SynchronizedStmt s | s.getEnclosingCallable() = ca | fieldAccessNotInsideStmt(s.getBlock().getLocation(), fa))
//   )
// }

predicate checkLocks(ControlFlowNode cLock, ControlFlowNode cUnlock) {
  if cLock.toString() = "lock(...)"
  then
    if cUnlock.toString() = "unlock(...)"
    then cLock.getAPredecessor().toString() = cUnlock.getAPredecessor().toString()
    else checkLocks(cLock, cUnlock.getASuccessor())
  else checkLocks(cLock.getAPredecessor(), cUnlock)
}

predicate checkIfPreOrSuccessorHasLock(Expr e){
  // not (e.toString() = "lock(...)" or e.toString() = "unlock(...)")
  not checkLocks(e.getControlFlowNode(), e.getControlFlowNode())
}

from Class c, Method m, Expr e
where 
  isElementInThreadSafeAnnotatedClass(c, m)
  and (e instanceof VariableUpdate or e instanceof Assignment or e instanceof MethodAccess)
  and not e.(MethodAccess).getQualifier().getType().toString() = "Lock"
  and not m.hasName("<obinit>")
  and e.getEnclosingCallable() = m
  and not m.isPrivate() // Should we have this as a recursive problem or just report the private method?
  // and hasNoSynchronizedThis(m, fa)
  and checkIfPreOrSuccessorHasLock(e)
select m, "Writes to a field. Consider it being in a synchronized block."
