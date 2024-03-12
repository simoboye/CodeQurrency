/**
 * @kind graph
 * @id shared/test
 */

 import java
 import semmle.code.java.Concurrency
 import annotation

 query predicate edges(Expr parent, Expr child, string label1, string label2) {
      parent = child.getControlFlowNode().getAPredecessor()
      and parent.getLocation().getFile().getBaseName() = "LockExample.java"
      and label2 = child.getControlFlowNode() + ":" + child.getControlFlowNode().getLocation().getStartLine()
      and (
        label1 = parent.getControlFlowNode() + ":" + parent.getControlFlowNode().getLocation().getStartLine()
        or
        exists(
          Field f | 
          child.(VariableUpdate).getDestVar() = f
          and label1 = f + ":" + f.getLocation().getStartLine()
        )
        or
        exists(
          Field f | 
          child.(FieldRead).getField() = f
          and label1 = f + ":" + f.getLocation().getStartLine()
        )
        or
        exists(
          Field f | 
          child.(MethodAccess).getQualifier() = f.getAnAccess() 
          and label1 = f + ":" + f.getLocation().getStartLine()
        )
        or
        exists(
          Field f | 
          child.(ArrayAccess).getArray() = f.getAnAccess() 
          and label1 = f + ":" + f.getLocation().getStartLine()
        )
      )
  }