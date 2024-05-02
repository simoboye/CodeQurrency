/**
 * @name Different lock global
 * @kind problem
 * @problem.severity warning
 * @id java/synchronized
 */ 

import java
import annotation
import immutable

predicate isFieldOccurencesAllOnSameLock(ControlFlowNode lock, Expr lastExpression) {
  if lastExpression instanceof VariableUpdate 
  then exists(
    VariableUpdate e, Field f |  
    not e = lastExpression 
    and lastExpression.(VariableUpdate).getDestVar() = f
    and e.getDestVar() = f |
    e.getControlFlowNode().getASuccessor+().toString() = lock.toString() and
    e.getControlFlowNode().getAPredecessor+().toString() = lock.toString()
  )
  else exists(
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
  if e instanceof VariableUpdate then exists(
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
  else
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

predicate removeLocalVariables(Expr e, Field f, Class c){
  if e instanceof VariableUpdate then
  e.(VariableUpdate).getDestVar() = f else
    if e instanceof FieldRead then
    e.(FieldRead).getField() = f else
    f != f
}

from Class c, Expr e, Field f
where 
  isImmutableField(f, c) implies isElementInThreadSafeAnnotatedClass(c, e.getEnclosingCallable())
  and
  removeLocalVariables(e, f, c)
  and (e instanceof VariableUpdate or e instanceof FieldRead)
  and not e.(FieldRead).getField().getType().hasName("Lock")
  and not e.getEnclosingCallable().hasName("<obinit>")
  and not e.getEnclosingCallable() instanceof Constructor
  and (
    if (
      hasSynchronizedBlock(e.getEnclosingStmt()) 
      or
      e.getEnclosingCallable().isSynchronized())
    then isSynchronizedOnSameObject(e)
    else not isSameLockAndAllFieldOccurences(e.getControlFlowNode(), e)
  )
select e, "An access of this field is on a different lock either in a synchronized statement or a lock type."
