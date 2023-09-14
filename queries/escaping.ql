import java

from Field f, string location
where
  location = f.getLocation().toString() and
  not location.regexpMatch(".*modules.*") and 
  not (f.isPrivate() or f.isFinal())
select f, "Potentially escaping field"
