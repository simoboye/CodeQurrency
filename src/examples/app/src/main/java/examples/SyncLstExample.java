package examples;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

@ThreadSafe
public class SyncLstExample<T> {
  private Lock lock = new ReentrantLock();
  private List<T> lst;

  public SyncLstExample(List<T> lst) {
    this.lst = lst;
  }

  public void push(T item) {
    lock.lock();
    lst.add(item);
    lock.unlock();
  }

  public void pop(int i) {
    lock.lock();
    lst.remove(i);
    lock.unlock();
  }
}

@ThreadSafe
class FaultySyncLstExample<T> {
  private Lock lock = new ReentrantLock();
  private List<T> lst;

  public FaultySyncLstExample(List<T> lst) {
    this.lst = lst;
  }

  public void push(T item) {
    lock.lock();
    lst.add(item);
    lock.unlock();
  }

  public void pop(int i) {
    lst.remove(i);
  }
}
