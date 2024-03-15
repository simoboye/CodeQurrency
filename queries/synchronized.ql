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

predicate compareExpectedLockToActualLock(ControlFlowNode cLock, ControlFlowNode cUnlock, ControlFlowNode currentLock) {
  if cLock.toString() = "lock(...)" 
  then
    if cUnlock.toString() = "unlock(...)"
    then cLock.getAPredecessor().toString() = currentLock.getAPredecessor().toString() 
      and cUnlock.getAPredecessor().toString() = currentLock.getAPredecessor().toString() 
    else compareExpectedLockToActualLock(cLock, cUnlock.getASuccessor(), currentLock)
  else compareExpectedLockToActualLock(cLock.getAPredecessor(), cUnlock, currentLock)
}

predicate isFieldOccurencesAllOnSameLock(Expr e, ControlFlowNode lock) {
  exists(
    Field f | 
    e.(VariableUpdate).getDestVar() = f | 
    compareExpectedLockToActualLock(
      e.getControlFlowNode(), 
      e.getControlFlowNode(), 
      lock
    )
  )
  or
  exists(
    Field f | 
    e.(FieldRead).getField() = f |
    compareExpectedLockToActualLock(
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
    compareExpectedLockToActualLock(
      e.getControlFlowNode(), 
      e.getControlFlowNode(), 
      lock
    )
  )
}

predicate isSameLockAndAllFieldOccurences(ControlFlowNode cLock, ControlFlowNode cUnlock, Expr e) {
  if cLock.toString() = "lock(...)"
  then
    if cUnlock.toString() = "unlock(...)"
    then cLock.getAPredecessor().toString() = cUnlock.getAPredecessor().toString() 
      and isFieldOccurencesAllOnSameLock(e, cUnlock.getAPredecessor())
    else isSameLockAndAllFieldOccurences(cLock, cUnlock.getASuccessor(), e)
  else isSameLockAndAllFieldOccurences(cLock.getAPredecessor(), cUnlock, e)
}





predicate compareExpectedLockToActualLockSync(Stmt syncLock, ControlFlowNode currentLock) {
  syncLock.getAQlClass() = "SynchronizedStmt" and not currentLock.toString() = syncLock.getControlFlowNode().getAPredecessor().toString()
  or compareExpectedLockToActualLockSync(syncLock.getEnclosingStmt(), currentLock)
}

predicate isFieldOccurencesAllOnSameLockSync(Expr e, ControlFlowNode lock) {
  exists(
    Field f | 
    e.(VariableUpdate).getDestVar() = f | 
    compareExpectedLockToActualLockSync(
      e.getEnclosingStmt(),
      lock
    )
  )
  or
  exists(
    Field f | 
    e.(FieldRead).getField() = f |
    compareExpectedLockToActualLockSync(
      e.getEnclosingStmt(),
      lock
    )
  )
  // or
  // exists(
  //   Field f | 
  //   e.(MethodAccess).getQualifier() = f.getAnAccess() |
  //   compareExpectedLockToActualLockSync(
  //     e.getEnclosingStmt(),
  //     lock
  //   )
  // )
  or
  exists(
    Field f | 
    e.(ArrayAccess).getArray() = f.getAnAccess() |
    compareExpectedLockToActualLockSync(
      e.getEnclosingStmt(),
      lock
    )
  )
}


predicate hasSynchronizedBlock(Expr e, Stmt s) {
  (s.getAQlClass() = "SynchronizedStmt" and isFieldOccurencesAllOnSameLockSync(e, s.getControlFlowNode().getAPredecessor())) or hasSynchronizedBlock(e, s.getEnclosingStmt())
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
  and not isSameLockAndAllFieldOccurences(e.getControlFlowNode(), e.getControlFlowNode(), e)
  and not hasSynchronizedBlock(e, e.getEnclosingStmt())
  and e.getLocation().getFile().getBaseName() = "LockExample.java"
  // and not m.isSynchronized()
select e, "Writes to a field. Consider it being in a synchronized block."

