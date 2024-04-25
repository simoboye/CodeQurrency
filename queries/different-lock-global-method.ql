/**
 * @name Synchronized
 * @kind problem
 * @problem.severity warning
 * @id java/synchronized
 */

import java
import annotation

predicate isFieldOccurencesAllOnSameLock(ControlFlowNode lock, Expr lastExpression) {
  exists(
    MethodAccess m |  
    not m = lastExpression and lastExpression.toString() = m.toString() |
    m.getControlFlowNode().getASuccessor+().toString() = lock.toString() and
    m.getControlFlowNode().getAPredecessor+().toString() = lock.toString()
  )
}

predicate isSameLockAndAllFieldOccurences(ControlFlowNode cLock, Expr e) {
  if cLock.toString() = "lock(...)"
  then isFieldOccurencesAllOnSameLock(cLock.getAPredecessor(), e)
  else isSameLockAndAllFieldOccurences(cLock.getAPredecessor(), e)
}

SynchronizedStmt getSyncStmt(Stmt s) {
  (s instanceof SynchronizedStmt and result = s.(SynchronizedStmt)
  or result = getSyncStmt(s.getEnclosingStmt()))
}
predicate hasSynchronizedBlock(Expr e, Stmt s) {
  s.getAQlClass() = "SynchronizedStmt" or hasSynchronizedBlock(e, s.getEnclosingStmt())
}

predicate isSynchronizedOnSameObject(Expr e) {  
  exists(
    MethodAccess newM |  
    not e = newM and e.toString() = newM.toString() |
    if e.getEnclosingCallable().isSynchronized()
    then "this" != getSyncStmt(newM.getEnclosingStmt()).getExpr().toString()
    else
      getSyncStmt(e.getEnclosingStmt()).getExpr().toString() !=
      getSyncStmt(newM.getEnclosingStmt()).getExpr().toString()
  )
}

from Class c, MethodAccess m
where 
  isElementInThreadSafeAnnotatedClass(c, m.getEnclosingCallable())
  and not m.getMethod().toString() = "lock" 
  and not m.getMethod().toString() = "unlock"
  and not m.getEnclosingCallable().toString() = "<obinit>"
  and not m.getEnclosingCallable() instanceof Constructor
  and (
    if (
      hasSynchronizedBlock(m, m.getEnclosingStmt()) 
      or
      m.getEnclosingCallable().isSynchronized())
    then isSynchronizedOnSameObject(m)
    else not isSameLockAndAllFieldOccurences(m.getControlFlowNode(), m)
  )
select m, "An access of this method is on a different lock either in a synchronized statement or a lock type."
