import java
import semmle.code.java.Concurrency
import annotation

// from FieldAccess fw
// where fw.getControlFlowNode().toString() = "lock"
// select fw.getControlFlowNode(), fw.getControlFlowNode().getAPredecessor()

// from AssignExpr t, InstanceAccess ia, FieldAccess fa
// where t.getControlFlowNode().getAPredecessor*().toString() = "lock(...)"
// select t.getControlFlowNode(), t.getAChildExpr()

// from VariableUpdate vu
// select vu

from Expr e
where 
  (e instanceof VariableUpdate or e instanceof Assignment or e instanceof MethodAccess)
  and 
  not e.getControlFlowNode().getAPredecessor*().toString() = "lock(...)"
  // e.(AssignExpr).getControlFlowNode().getAPredecessor*().toString() = "lock(...)" 
  // or e.(FieldAccess).getControlFlowNode().getAPredecessor*().toString() = "lock(...)"
select e

