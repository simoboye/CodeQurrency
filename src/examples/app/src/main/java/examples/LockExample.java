package examples;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

@ThreadSafe
public class LockExample {
  private Lock lock1 = new ReentrantLock();
  private Lock lock2 = new ReentrantLock();

  private int length = 0;
  private int notRelatedToOther = 10;
  private int[] content  = new int[10];

  public void add(int value) {
    lock1.lock();
    length++;
    content[length] = value;
    lock1.unlock();
  }

  public void removeCorrect() {
    lock1.lock();
    length--;
    content[length] = 0;
    lock1.unlock();
  }

  public void notTheSameLockAsAdd() { // use locks, but t
    lock2.lock();
    length--;
    content[length] = 0;
    lock2.unlock();
  }

  public void noLock() { // no locks
    length--;
    content[length] = 0;
  }

  public void fielddUpdatedOutsideOfLock() { // adjusts length without lock
    length--;

    lock1.lock();
    content[length] = 0;
    lock1.unlock();
  }

  public synchronized void synchronizedLock() { // no locks, but with synchronized
    length--;
    content[length] = 0;
  }

  public void onlyLocked() { // never unlocked, only locked
    length--;

    lock1.lock();
    content[length] = 0;
  }

  public void onlyUnlocked() { // never locked, only unlocked
    length--;

    content[length] = 0;
    lock1.unlock();
  }

  public void notSameLock() {
    length--;

    lock2.lock();// Not the same lock
    content[length] = 0;
    lock1.unlock();
  }

  public void updateCount() {
    lock2.lock();
    notRelatedToOther++;
    lock2.unlock();
  }

}