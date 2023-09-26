import java

predicate isPrivate(Field f, FieldAccess fa) {
  // f.isPrivate() and 
  fa.getField().isPrivate()
}

predicate isReferencedOutsideLock(Field f, Class c, Method m, FieldAccess fa) {
  // isPrivate(f) and We think that we will report this twice if it is public
  // c.hasChildElement(fa.getField())
  // and m.hasName("lock")
  //and fa.isOwnFieldAccess()
  // and fa.getEnclosingCallable().calls(m) // har en lock rundt om sig
  // fa.getSite()
  m.hasName("lock")
  and not fa.getSite().toString() = "<obinit>"
  and not fa.getSite().getDeclaringType().toString() = fa.getSite().toString()
  // and fa.getSite().getBody().
}

predicate isEscaping(Field f, Class c, Method m, FieldAccess fa) {
  not f.getLocation().toString().regexpMatch(".*modules.*")
  and not isPrivate(f, fa)
  and isReferencedOutsideLock(f, c, m, fa)
}

from Field f, Class c, Method m, FieldAccess fa
where isEscaping(f, c, m, fa)
select fa, "Potentially escaping field", fa.getSite(), fa.getSite().getBody().getLocation()
