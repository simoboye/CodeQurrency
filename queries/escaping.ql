import java

predicate isPrivate(Field f) {
  f.isPrivate()
}

predicate isReferencedOutsideLock(Field f, Class c, Method m) {
  // isPrivate(f) and We think that we will report this twice if it is public
  c.hasChildElement(f)
  and m.hasName("lock")
  and f.getAnAccess().getEnclosingCallable().calls(m)
  //and f.getAnAccess() // har en lock rundt om sig
}

predicate isEscaping(Field f, Class c, Method m) {
  not f.getLocation().toString().regexpMatch(".*modules.*")
  and not isPrivate(f)
  and isReferencedOutsideLock(f, c, m)
}

from Field f, Class c, Method m
where isEscaping(f, c, m)
select f.getAnAccess(), "Potentially escaping field", f.getLocation(), c.getName()
