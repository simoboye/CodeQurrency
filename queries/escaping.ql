/**
 * @name Escaping
 * @kind problem
 * @problem.severity warning
 * @id java/escaping
 */

import java
import annotation

predicate isNotPrivate(Field f) {
  not f.isPrivate()
}

from Field f, Class c
where isFieldInThreadSafeAnnotatedClass(c, f) 
  and isNotPrivate(f)
  and not f.isFinal()
select f, "Potentially escaping field"
