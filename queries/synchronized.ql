/**
 * @name Synchronized
 * @kind problem
 * @problem.severity warning
 * @id java/synchronized
 */

import java
import annotation
import semmle.code.java.Concurrency

predicate compareExpectedLockToActualLock(ControlFlowNode cLock, ControlFlowNode cUnlock, ControlFlowNode currentLock) {
  if cLock.toString() = "lock(...)" 
  then
    if cUnlock.toString() = "unlock(...)"
    then 
      cLock.getAPredecessor().toString() = currentLock.toString()
      and cUnlock.getAPredecessor().toString() = currentLock.toString() 
    else compareExpectedLockToActualLock(cLock, cUnlock.getASuccessor(), currentLock)
  else compareExpectedLockToActualLock(cLock.getAPredecessor(), cUnlock, currentLock)
}

predicate isFieldOccurencesAllOnSameLock(Field f, ControlFlowNode lock, Expr lastExpression) {
  // exists(
  //   Field f | 
  //   e.(VariableUpdate).getDestVar() = f | 
  //   compareExpectedLockToActualLock(
  //     e.getControlFlowNode(), 
  //     e.getControlFlowNode(), 
  //     lock
  //   )
  // )

  exists(
    Expr e | 
    not e = lastExpression and e.(VariableUpdate).getDestVar() = f | 
    compareExpectedLockToActualLock(
      e.getControlFlowNode(), 
      e.getControlFlowNode(), 
      lock
    )
    // e1 = e1
  )

  // or
  // exists(
  //   Field f | 
  //   e.(FieldRead).getField() = f |
  //   compareExpectedLockToActualLock(
  //     e.getControlFlowNode(), 
  //     e.getControlFlowNode(), 
  //     lock
  //   )
  // )
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
  // or
  // exists(
  //   Field f | 
  //   e.(ArrayAccess).getArray() = f.getAnAccess() |
  //   compareExpectedLockToActualLock(
  //     e.getControlFlowNode(), 
  //     e.getControlFlowNode(), 
  //     lock
  //   )
  // )
}

predicate isSameLockAndAllFieldOccurences(ControlFlowNode cLock, ControlFlowNode cUnlock, Field f, Expr e) {
  if cLock.toString() = "lock(...)"
  then
    if cUnlock.toString() = "unlock(...)"
    then cLock.getAPredecessor().toString() = cUnlock.getAPredecessor().toString() 
      and isFieldOccurencesAllOnSameLock(f, cUnlock.getAPredecessor(), e)
    else isSameLockAndAllFieldOccurences(cLock, cUnlock.getASuccessor(), f, e)
  else isSameLockAndAllFieldOccurences(cLock.getAPredecessor(), cUnlock, f, e)
}





// predicate compareExpectedLockToActualLockSync(Stmt syncLock, ControlFlowNode currentLock) {
//   syncLock.getAQlClass() = "SynchronizedStmt" and currentLock.toString() = syncLock.getControlFlowNode().getAPredecessor().toString()
//   or compareExpectedLockToActualLockSync(syncLock.getEnclosingStmt(), currentLock)
// }

// predicate isFieldOccurencesAllOnSameLockSync(Expr e, ControlFlowNode lock) {
//   exists(
//     Field f | 
//     e.(VariableUpdate).getDestVar() = f | 
//     compareExpectedLockToActualLockSync(
//       e.getEnclosingStmt(),
//       lock
//     )
//   )
//   or
//   exists(
//     Field f | 
//     e.(FieldRead).getField() = f |
//     compareExpectedLockToActualLockSync(
//       e.getEnclosingStmt(),
//       lock
//     )
//   )
  // or
  // exists(
  //   Field f | 
  //   e.(MethodAccess).getQualifier() = f.getAnAccess() |
  //   compareExpectedLockToActualLockSync(
  //     e.getEnclosingStmt(),
  //     lock
  //   )
  // )
//   or
//   exists(
//     Field f | 
//     e.(ArrayAccess).getArray() = f.getAnAccess() |
//     compareExpectedLockToActualLockSync(
//       e.getEnclosingStmt(),
//       lock
//     )
//   )
// }


// predicate hasSynchronizedBlock(Expr e, Stmt s) {
//   (s.getAQlClass() = "SynchronizedStmt" and isFieldOccurencesAllOnSameLockSync(e, s.getControlFlowNode().getAPredecessor())) or hasSynchronizedBlock(e, s.getEnclosingStmt())
// }

from Class c, Method m, Expr e, Field f
where 
  isElementInThreadSafeAnnotatedClass(c, m)
  and (e instanceof VariableUpdate /*or e instanceof FieldRead or e instanceof ArrayAccess /*or e instanceof MethodAccess*/)
  // Currently we need to resursively handle methodaccesses and look at those for potentially changed fields.
  // and not e.(FieldRead).getField().getType().toString() = "Lock"
  and not m.hasName("<obinit>")
  and e.getEnclosingCallable() = m
  and not m.isPrivate() // Should we have this as a recursive problem or just report the private method?
  // and hasNoSynchronizedThis(m, e) // Rewrite this to look at controlflownodes
  and e.(VariableUpdate).getDestVar() = f
  and not isSameLockAndAllFieldOccurences(e.getControlFlowNode(), e.getControlFlowNode(), f, e)
  // and hasSynchronizedBlock(e, e.getEnclosingStmt())
  // and e.getLocation().getFile().getBaseName() = "LockCorrect.java"
  // and not m.isSynchronized()
select e, "Writes to a field. Consider it being in a synchronized block."

