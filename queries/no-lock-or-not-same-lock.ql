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
  s.getAQlClass() = "SynchronizedStmt" or hasSynchronizedBlock(s.getEnclosingStmt())
}

from Class c, Expr e, Field f
where 
  isElementInThreadSafeAnnotatedClass(c, e.getEnclosingCallable())
  and (e instanceof VariableUpdate or e instanceof FieldRead)
  and not e.getEnclosingCallable().hasName("<obinit>")
  and not e.getEnclosingCallable() instanceof Constructor
  and (
    e.(VariableUpdate).getDestVar() = f or
    e.(FieldRead).getField() = f
  )
  and not isImmutableField(f, c)
  and not isSameLockAndAllFieldOccurences(e.getControlFlowNode(), e.getControlFlowNode())
  and not hasSynchronizedBlock(e.getEnclosingStmt())
  and not e.getEnclosingCallable().isSynchronized()
select e, "Writes to a field. Consider it being in a lock and make sure that the lock and unlock is on the same object."
