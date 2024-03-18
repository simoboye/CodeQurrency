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

predicate isFieldOccurencesAllOnSameLock(Field f, ControlFlowNode lock, Expr lastExpression, Class c) {

  exists(
    Expr e | 
    not e = lastExpression and 
    isElementInThreadSafeAnnotatedClass(c, e.getEnclosingCallable()) and 
    e.(VariableUpdate).getDestVar() = f | 
    compareExpectedLockToActualLock(
      e.getControlFlowNode(), 
      e.getControlFlowNode(), 
      lock
    )
  )
}

predicate isSameLockAndAllFieldOccurences(ControlFlowNode cLock, ControlFlowNode cUnlock, Field f, Expr e, Class c) {
  if cLock.toString() = "lock(...)"
  then
    if cUnlock.toString() = "unlock(...)"
    then 
    cLock.getAPredecessor().toString() = cUnlock.getAPredecessor().toString() and
    isFieldOccurencesAllOnSameLock(f, cUnlock.getAPredecessor(), e, c)
    else isSameLockAndAllFieldOccurences(cLock, cUnlock.getASuccessor(), f, e, c)
  else isSameLockAndAllFieldOccurences(cLock.getAPredecessor(), cUnlock, f, e, c)
}

from Class c, Method m, Expr e, Field f
where 
  isElementInThreadSafeAnnotatedClass(c, m)
  and (e instanceof VariableUpdate /*or e instanceof FieldRead or e instanceof ArrayAccess /*or e instanceof MethodAccess*/)
  // Currently we need to resursively handle methodaccesses and look at those for potentially changed fields.
  // and not e.(FieldRead).getField().getType().toString() = "Lock"
  and not m.hasName("<obinit>")
  and e.getEnclosingCallable() = m
  and not m.isPrivate() // Should we have this as a recursive problem or just report the private method?
  and e.(VariableUpdate).getDestVar() = f
  and not isSameLockAndAllFieldOccurences(e.getControlFlowNode(), e.getControlFlowNode(), f, e, c)
  // and hasSynchronizedBlock(e, e.getEnclosingStmt())
  // and e.getLocation().getFile().getBaseName() = "LockCorrect.java"
  // and not m.isSynchronized()
select e, "Writes to a field. Consider it being in a synchronized block."

