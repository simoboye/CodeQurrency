import java

predicate isFieldInThreadSafeAnnotatedClass(Class c, Field f) {
  c.getAnAnnotation().toString() = "ThreadSafe"
  and c.declaresField(f.getName())
}

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
  count(FieldWrite fw | fw.getField() = f and fw.getEnclosingCallable().hasName("<obinit>") | fw))
  = 0
}

predicate isNotSafelyPublished(Field f) {
  not (f.isFinal() or isDefaultValue(f)) 
}

// What about other datatypes
// https://docs.oracle.com/javase/tutorial/java/nutsandbolts/datatypes.html -- See default values
// And what about arrays?
predicate isDefaultValue(Field f) {
  (f.getType().hasName("int") and f.getAnAssignedValue().toString() = "0")
  or (f.getType().hasName("boolean") and f.getAnAssignedValue().toString() = "false")  
  or f.getAnAssignedValue().toString() = "null"
}

from Field f, Class c
where isFieldInThreadSafeAnnotatedClass(c, f)
and isImmutableField(f, c)
and isNotSafelyPublished(f)
select f, f.getAnAssignedValue()
