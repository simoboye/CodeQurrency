import java

predicate isFieldInThreadSafeAnnotatedClass(Class c, Field f) {
  c.getAnAnnotation().toString() = "ThreadSafe"
  and c.contains(f)
}

predicate isMethodInThreadSafeAnnotatedClass(Class c, Method m) {
  c.getAnAnnotation().toString() = "ThreadSafe"
  and c.contains(m) //c.hasMethod(m, c)
}
