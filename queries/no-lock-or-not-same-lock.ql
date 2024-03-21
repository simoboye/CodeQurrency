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

from Class c, Method m, Expr e, Field f
where 
  isElementInThreadSafeAnnotatedClass(c, m)
  and (e instanceof VariableUpdate or e instanceof FieldRead)
  // and not e.(FieldRead).getField().getType().toString() = "Lock" // We did this because we sometimes report locks that did not have a lock above/beneath (which makes no sense)
  and not m.hasName("<obinit>")
  and e.getEnclosingCallable() = m
  and not m.isPrivate()
  and (
    e.(VariableUpdate).getDestVar() = f or
    e.(FieldRead).getField() = f
  )
  and not isImmutableField(f, c)
  and not isSameLockAndAllFieldOccurences(e.getControlFlowNode(), e.getControlFlowNode())
  and not hasSynchronizedBlock(e.getEnclosingStmt())
  and not m.isSynchronized()
select e, "Writes to a field. Consider it being in a lock and make sure that the lock and unlock is on the same object."
