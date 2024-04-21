/**
 * @name Synchronized
 * @kind problem
 * @problem.severity warning
 * @id java/synchronized
 */

import java
import annotation
import immutable

predicate isFieldOccurencesAllOnSameLock(ControlFlowNode lock, Expr lastExpression) {
  exists(
    VariableUpdate e, Field f |  
    not e = lastExpression 
    and lastExpression.(VariableUpdate).getDestVar() = f
    and e.getDestVar() = f |
    e.getControlFlowNode().getASuccessor+().toString() = lock.toString() and
    e.getControlFlowNode().getAPredecessor+().toString() = lock.toString()
  )
  or
  exists(
    FieldRead e, Field f |  
    not e = lastExpression 
    and lastExpression.(FieldRead).getField() = f
    and e.getField() = f |
    e.getControlFlowNode().getASuccessor+().toString() = lock.toString() and
    e.getControlFlowNode().getAPredecessor+().toString() = lock.toString()
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
predicate hasSynchronizedBlock(Stmt s) {
  s instanceof SynchronizedStmt or hasSynchronizedBlock(s.getEnclosingStmt())
}

predicate isSynchronizedOnSameObject(Expr e) {  
  exists(
    VariableUpdate newE, Field f |  
    not e = newE 
    and e.(VariableUpdate).getDestVar() = f
    and newE.getDestVar() = f |
    if e.getEnclosingCallable().isSynchronized()
    then "this" != getSyncStmt(newE.getEnclosingStmt()).getExpr().toString()
    else
      getSyncStmt(e.getEnclosingStmt()).getExpr().toString() !=
      getSyncStmt(newE.getEnclosingStmt()).getExpr().toString()
  )
  or
  exists(
    FieldRead newE, Field f |  
    not e = newE 
    and e.(FieldRead).getField() = f
    and newE.getField() = f |
    if e.getEnclosingCallable().isSynchronized()
    then "this" != getSyncStmt(newE.getEnclosingStmt()).getExpr().toString()
    else
      getSyncStmt(e.getEnclosingStmt()).getExpr().toString() !=
      getSyncStmt(newE.getEnclosingStmt()).getExpr().toString()
  )
}

predicate removeLocalVariables(Expr e, Field f){
  e.(VariableUpdate).getDestVar() = f or
  e.(FieldRead).getField() = f
}

from Class c, Expr e, Field f
where 
  isElementInThreadSafeAnnotatedClass(c, e.getEnclosingCallable())
  and not isImmutableField(f, c)
  and (e instanceof VariableUpdate or e instanceof FieldRead)
  and not e.(FieldRead).getField().getType().toString() = "Lock"
  and not e.getEnclosingCallable().hasName("<obinit>")
  and not e.getEnclosingCallable() instanceof Constructor
  and removeLocalVariables(e, f)
  and (
    if (
      hasSynchronizedBlock(e.getEnclosingStmt()) 
      or
      e.getEnclosingCallable().isSynchronized())
    then isSynchronizedOnSameObject(e)
    else not isSameLockAndAllFieldOccurences(e.getControlFlowNode(), e)
  )
select e, "An access of this field is on a different lock either in a synchronized statement or a lock type."
