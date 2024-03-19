/**
 * @kind graph
 * @id shared/test
 */

 import java
 import semmle.code.java.Concurrency
 import annotation

//  query predicate edges(Expr parent, Expr child, string label1, string label2) {
//       parent = child.getControlFlowNode().getAPredecessor()
//       and parent.getLocation().getFile().getBaseName() = "LockExample.java"
//       and label2 = child.getControlFlowNode() + ":" + child.getControlFlowNode().getLocation().getStartLine()
//       and (
//         label1 = parent.getControlFlowNode() + ":" + parent.getControlFlowNode().getLocation().getStartLine()
//         or
//         exists(
//           Field f | 
//           child.(VariableUpdate).getDestVar() = f
//           and label1 = f + ":" + f.getLocation().getStartLine()
//         )
//         or
//         exists(
//           Field f | 
//           child.(FieldRead).getField() = f
//           and label1 = f + ":" + f.getLocation().getStartLine()
//         )
//         or
//         exists(
//           Field f | 
//           child.(MethodAccess).getQualifier() = f.getAnAccess() 
//           and label1 = f + ":" + f.getLocation().getStartLine()
//         )
//         or
//         exists(
//           Field f | 
//           child.(ArrayAccess).getArray() = f.getAnAccess() 
//           and label1 = f + ":" + f.getLocation().getStartLine()
//         )
//       )
//   }

// query predicate sync(Expr e, string label1) {
//   label1 = e.getControlFlowNode().getAPredecessor*().toString()
//   and label1.matches("synchronized (...)") and e.getLocation().getFile().getBaseName() = "LockExample.java"
// }

// predicate test(Expr e) {
//   e.getControlFlowNode().getBasicBlock()
// }

predicate test2(Stmt e) {
  e.getAQlClass() = "SynchronizedStmt" or test2(e.getEnclosingStmt())
}

string test(Stmt e) {
    if e.getEnclosingStmt().getAQlClass() = "SynchronizedStmt"
    then result = e.getEnclosingStmt().(SynchronizedStmt).getExpr().toString()
    else result = test(e.getEnclosingStmt()) 
}

from Expr e
where e.getLocation().getFile().getBaseName() = "LockExample.java"
and not test2(e.getEnclosingStmt())
select e//, test(e.getEnclosingStmt())