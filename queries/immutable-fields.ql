import java

// TODO: Check this case
// public class S {
//   String count = null
//   public S () {
//     count = null 
//   }
// }
// This is written twice? But it is still only initializing

predicate isImmutableField(Field f) {
  count(FieldWrite fw | f = fw.getField() | fw) = 1
}

predicate isNotSafelyPublished(Field f) {
  not (f.isFinal() or f.getAnAssignedValue().toString() = "null") 
}

from Field f
where isImmutableField(f)
and isNotSafelyPublished(f)
select f, f.getAnAssignedValue()