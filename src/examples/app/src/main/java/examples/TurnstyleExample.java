package examples;

import java.util.Stack;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

@ThreadSafe
public class TurnstyleExample {
  private Lock lock = new ReentrantLock();
  private int count = 0;

  public void inc() {
    lock.lock();
    count++;
    lock.unlock();
  }

  public void dec() {
    lock.lock();
    count--;
    lock.unlock();
  }
}

@ThreadSafe
class FaultyTurnstyleExample {
  private Lock lock = new ReentrantLock();
  private int count = 0;

  public void inc() {
    lock.lock();
    count++;
    lock.unlock();
  }

  public void dec() {
    count--;
  }
}
