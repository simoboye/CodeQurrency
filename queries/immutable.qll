import java

predicate isImmutableField(Field f, Class c) {
  f.isFinal() or
  count(FieldWrite fw | fw.getField() = f | fw) -
  (count(FieldWrite fw | fw.getField() = f and fw.getEnclosingCallable().hasName(c.getName()) | fw) + 
  count(FieldWrite fw | fw.getField() = f and fw.getEnclosingCallable().hasName("<obinit>") | fw)) = 0
}
