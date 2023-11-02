import java
import semmle.code.java.Concurrency

from SynchronizedStmt st, SynchronizedCallable sc
select st.getExpr()

//from Method m
//select m
