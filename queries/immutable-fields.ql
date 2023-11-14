/**
 * @name immutable-fields
 * @kind problem
 * @problem.severity warning
 * @id java/immutable-fields
 */


import java
import annotation
import semmle.code.java.Concurrency

// TODO: Check this case
// public class S {
//   String count = null
//   public S () {
//     count = null 
//   }
// }
// This is written twice? But it is still only initializing
// From 17.5 https://docs.oracle.com/javase/specs/jls/se8/html/jls-17.html
// An object is considered to be completely initialized when its constructor finishes. 
// A thread that can only see a reference to an object after that object has been completely initialized is guaranteed to see the correctly initialized values for that object's final fields.
// So I guess that the above example should be considered safely published?

predicate isImmutableField(Field f, Class c) {
  count(FieldWrite fw | fw.getField() = f | fw) -
  (count(FieldWrite fw | fw.getField() = f and fw.getEnclosingCallable().hasName(c.getName()) | fw) + 
  count(FieldWrite fw | fw.getField() = f and fw.getEnclosingCallable().hasName("<obinit>") | fw)) = 0
}

from Field f, Class c
where isFieldInThreadSafeAnnotatedClass(c, f)
and isImmutableField(f, c)
and locallySynchronizedOnThis(f.getAnAccess(), c)
select f, "is immutable field, and should not be accessed in a syncronized way"
