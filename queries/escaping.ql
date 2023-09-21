import java

predicate isPrivate(Field f) {
  f.isPrivate()
}

predicate isReferencedOutsideLock(Field f, Class c) {
  isPrivate(f)
  and c.hasChildElement(f)
  //and f.getAnAccess() // har en lock rundt om sig
}

predicate isEscaping(Field f, Class c) {
  not f.getLocation().toString().regexpMatch(".*modules.*")
  and not isPrivate(f)
  and isReferencedOutsideLock(f, c)
}

from Field f, Class c
where isEscaping(f, c)
select f, "Potentially escaping field", f.getLocation(), c.getName()
