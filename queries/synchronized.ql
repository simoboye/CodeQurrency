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

predicate checkFieldOccurences(Expr e, ControlFlowNode lock) {
  exists(
    Field f | 
    e.(VariableUpdate).getDestVar() = f | 
    checkLocks2(
      e.getControlFlowNode(), 
      e.getControlFlowNode(), 
      lock
    )
  )
  or
  exists(
    Field f | 
    e.(FieldRead).getField() = f |
    checkLocks2(
      e.getControlFlowNode(), 
      e.getControlFlowNode(), 
      lock
    )
  )
  // or
  // exists(
  //   Field f | 
  //   e.(MethodAccess).getQualifier() = f.getAnAccess() |
  //   checkLocks2(
  //     e.getControlFlowNode(), 
  //     e.getControlFlowNode(), 
  //     lock
  //   )
  // )
  or
  exists(
    Field f | 
    e.(ArrayAccess).getArray() = f.getAnAccess() |
    checkLocks2(
      e.getControlFlowNode(), 
      e.getControlFlowNode(), 
      lock
    )
  )
}

predicate checkLocks2(ControlFlowNode cLock, ControlFlowNode cUnlock, ControlFlowNode currentLock) {
  if cLock.toString() = "lock(...)" 
  then
    if cUnlock.toString() = "unlock(...)"
    then cLock.getAPredecessor().toString() = currentLock.getAPredecessor().toString() 
      and cUnlock.getAPredecessor().toString() = currentLock.getAPredecessor().toString() 
    else checkLocks2(cLock, cUnlock.getASuccessor(), currentLock)
  else checkLocks2(cLock.getAPredecessor(), cUnlock, currentLock)
}

predicate checkLocks(ControlFlowNode cLock, ControlFlowNode cUnlock, Expr e) {
  if cLock.toString() = "lock(...)"
  then
    if cUnlock.toString() = "unlock(...)"
    then cLock.getAPredecessor().toString() = cUnlock.getAPredecessor().toString() 
      and checkFieldOccurences(e, cUnlock.getAPredecessor())
    else checkLocks(cLock, cUnlock.getASuccessor(), e)
  else checkLocks(cLock.getAPredecessor(), cUnlock, e)
}

from Class c, Method m, Expr e
where 
  isElementInThreadSafeAnnotatedClass(c, m)
  and (e instanceof VariableUpdate or e instanceof FieldRead or e instanceof ArrayAccess /*or e instanceof MethodAccess*/)
  // Currently we need to resursively handle methodaccesses and look at those for potentially changed fields.
  and not e.(FieldRead).getField().getType().toString() = "Lock"
  and not m.hasName("<obinit>")
  and e.getEnclosingCallable() = m
  and not m.isPrivate() // Should we have this as a recursive problem or just report the private method?
  // and hasNoSynchronizedThis(m, e) // Rewrite this to look at controlflownodes
  and not checkLocks(e.getControlFlowNode(), e.getControlFlowNode(), e)
select m, "Writes to a field. Consider it being in a synchronized block."

