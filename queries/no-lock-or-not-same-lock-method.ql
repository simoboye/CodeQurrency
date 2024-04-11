/**
 * @name Mutual exclusion absense
 * @kind problem
 * @problem.severity warning
 * @id java/no-lock-or-not-same-lock
 */

import java
import annotation
import immutable

predicate isSameLockAndAllFieldOccurences(ControlFlowNode cLock, ControlFlowNode cUnlock) {
  if cLock.toString() = "lock(...)"
  then
    if cUnlock.toString() = "unlock(...)"
    then cLock.getAPredecessor().toString() = cUnlock.getAPredecessor().toString() 
    else isSameLockAndAllFieldOccurences(cLock, cUnlock.getASuccessor())
  else isSameLockAndAllFieldOccurences(cLock.getAPredecessor(), cUnlock)
}

predicate hasSynchronizedBlock(Stmt s) {
  s. getAQlClass() = "SynchronizedStmt" or hasSynchronizedBlock(s.getEnclosingStmt())
}

from Class c, MethodAccess m
where 
  isElementInThreadSafeAnnotatedClass(c, m.getEnclosingCallable())
  // and (e instanceof VariableUpdate or e instanceof FieldRead)
  // and not e.(FieldRead).getField().getType().toString() = "Lock" // We did this because we sometimes report locks that did not have a lock above/beneath (which makes no sense)
  and not m.getMethod().toString() = "lock" 
  and not m.getMethod().toString() = "unlock"
  and not m.getMethod().toString() = "<obinit>"
  and not m.getEnclosingCallable() instanceof Constructor
  and not isSameLockAndAllFieldOccurences(m.getControlFlowNode(), m.getControlFlowNode())
  and not hasSynchronizedBlock(m.getEnclosingStmt())
  and not m.getEnclosingCallable().isSynchronized()
select m, "Consider the method it being in a lock and make sure that the lock and unlock is on the same object."
