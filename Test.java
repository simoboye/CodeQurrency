import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class Test {
  /**
   * Escaping field due to public visuability.
   */
  int publicField;
  
  private int y;

  // As of the below examples with syncronized as well. Except the incorretly placed lock.

  private Lock lock = new ReentrantLock();

  /**
   * Calls the a method where y field escapes.
   * @param y
   */
  public void setYAgainInCorrect(int y) {
    setYPrivate(y);
  }

  /**
   * Locks the method where y field escapes.
   * @param y
   */
  public void setYAgainCorrect(int y) {
    lock.lock();
    setYPrivate(y);
    lock.unlock();
  }

  /**
   * No escaping y field. Locks the y before assignment.
   * @param y
   */
  public void setYCorrect(int y) {
    lock.lock();
    this.y = y;
    lock.unlock();
  }

  /**
   * No direct escaping, since it method is private. Only escaping if another public method uses this.
   * @param y
   */
  private void setYPrivate(int y) {
    this.y = y;
  }

  /**
   * Incorretly locks y.
   * @param y
   */
  public void setYWrongLock(int y) {
    this.y = y;
    lock.lock();
    lock.unlock();
  }
}