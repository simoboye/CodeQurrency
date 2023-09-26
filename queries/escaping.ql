import java

predicate isPrivate(FieldAccess fa) {
  fa.getField().isPrivate()
}

predicate isReferencedOutsideLock(FieldAccess fa, MethodAccess ma) {
  // limitation: this will not field accesses that is not thread safe if there is not a lock present
  // it does also not take into account unlock.
  // limitation: can not see if a method is syncronized
  // limitation: 
  // isPrivate(f) and We think that we will report this twice if it is public
  ma.getMethod().hasName("lock")
  and not fa.getSite().toString() = "<obinit>"
  and not fa.getSite().getDeclaringType().toString() = fa.getSite().toString()
  and fa.getSite() = ma.getEnclosingCallable()
  and fa.getLocation().getStartLine() < ma.getLocation().getStartLine()
  
}

predicate isEscaping(FieldAccess fa, MethodAccess ma) {
  not fa.getField().getLocation().toString().regexpMatch(".*modules.*")
  and not isPrivate(fa)
  and isReferencedOutsideLock(fa, ma)
}

from FieldWrite fa, MethodAccess ma //, FieldAccess fa
where isEscaping(fa, ma)
select fa, "Potentially escaping field", fa.getLocation().getStartLine(), ma.getLocation(), fa.getSite(), ma.getEnclosingCallable()
