@ThreadSafe
public class ThreadSafeClass {  
  private int y;

  public ThreadSafeClass() {
    this.y = 0;
  }

  public int getY() {
    return y;
  }
}
