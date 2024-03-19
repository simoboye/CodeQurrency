/**
 * @name Synchronized
 * @kind problem
 * @problem.severity warning
 * @id java/synchronized
 */

import java
import annotation
import semmle.code.java.Concurrency

predicate isFieldOccurencesAllOnSameLock(ControlFlowNode lock, Expr lastExpression) {
  exists(
    VariableUpdate e, Field f |  
    not e = lastExpression 
    and lastExpression.(VariableUpdate).getDestVar() = f
    and e.getDestVar() = f |
    e.getControlFlowNode().getASuccessor+().toString() = lock.toString() and
    e.getControlFlowNode().getAPredecessor+().toString() = lock.toString()
  )
}

predicate isSameLockAndAllFieldOccurences(ControlFlowNode cLock, Expr e) {
  if cLock.toString() = "lock(...)"
  then isFieldOccurencesAllOnSameLock(cLock.getAPredecessor(), e)
  else isSameLockAndAllFieldOccurences(cLock.getAPredecessor(), e)
}

SynchronizedStmt t(Expr e, Stmt s) {
  (s.getAQlClass() = "SynchronizedStmt" and result = s.(SynchronizedStmt) 
  or result = t(e, s.getEnclosingStmt()))
}
predicate hasSynchronizedBlock(Expr e, Stmt s) {
  s.getAQlClass() = "SynchronizedStmt" or hasSynchronizedBlock(e, s.getEnclosingStmt())
}

predicate isSynchronizedOnSameObject(Expr e) {  
  exists(
    VariableUpdate e1, Field f |  
    not e = e1 
    and e.(VariableUpdate).getDestVar() = f
    and e1.getDestVar() = f |
    if e.getEnclosingCallable().isSynchronized()
    then "this" !=
           t(e1, e1.getEnclosingStmt()).getExpr().toString()
    else
      t(e, e.getEnclosingStmt()).getExpr().toString() !=
      t(e1, e1.getEnclosingStmt()).getExpr().toString()
  )
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
  and (
    if (
      hasSynchronizedBlock(e, e.getEnclosingStmt()) 
      or
      e.getEnclosingCallable().isSynchronized())
    then isSynchronizedOnSameObject(e)
    else not isSameLockAndAllFieldOccurences(e.getControlFlowNode(), e)
  )
select e, "Writes to a field. Consider it being in a synchronized block."

