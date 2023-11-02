import java
import semmle.code.java.Concurrency

predicate isFieldInThreadSafeAnnotatedClass(Class c, Field f) {
  c.getAnAnnotation().toString() = "ThreadSafe"
  and c.declaresField(f.getName())
}
//from SynchronizedStmt st, Method m
//where m.hasName(st.getEnclosingCallable().getName())
//or m.isSynchronized()
//and not m.getLocation().toString().regexpMatch(".*modules.*")
//select m

from FieldAccess f, Class c, SynchronizedStmt st //SynchronizedCallable sc
where isFieldInThreadSafeAnnotatedClass(c, f.getField())
and locallySynchronizedOn(st.getExpr(), st, f.getField())
//and (f.getEnclosingCallable() = st.getEnclosingCallable() or f.getEnclosingCallable().isSynchronized())
select f, f.getEnclosingCallable(), f.getEnclosingCallable().getACallee()