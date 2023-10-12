import java

from Class c
where c.getAnAnnotation().toString() = "ThreadSafe"
select c, c.getAnAnnotation()
