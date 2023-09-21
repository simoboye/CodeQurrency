
# Thread safe classes

A **class** is said to be **thread-safe** if and only if no concurrent execution of method calls or field accesses (read/write) result in race conditions.

A concurrent **program** is said to be **thread-safe** if and only if it is race condition free.

For any program p, p only accesses thread-safe *classes* does not imply that p is a thread-safe *program*.
Since program using thread-safe classes may contain race conditions.

## Class state

Identifying the fields that may be shared by several threads.

## Escaping

Not exposing shared state variables.

E.g. if a field is made public, then it can be accessed by different threads outside of any potential locks that manipulate a field.

```Java
class Counter {
  // class sate (variables)
  int i = 0;

  public synchronized void inc() {
    i++;
  }
}
```

```Java
Counter c = new Counter();
new Thread(() -> {
  c.inc();
}).start();

new Thread(() -> {
  c.i++;
}).start();
```

## (Safe) publication

Initialization *happends-before* publication.

All fields must be corretly initialized before it is made accessible as a reference to an object.

Make the fields volatile or final.
(Final of course only works if the value of the field is never changed)

## Immutability

- An immutable object is one whose state cannot be changed after initialization
    - In Java: the final keyword prevents modification of fields
- A immutable class is one whose instances are immutable objects
    - When a class is immutable, it is not sufficient to just declare all variables as immutable: immutable objects (final) fields can still hold refrences to mutable objects (e.g. another class object with fields that are mutable)

## Mutual exclusion

- Whenever shared mutable state is accessed by several threads it must be protected by locks
