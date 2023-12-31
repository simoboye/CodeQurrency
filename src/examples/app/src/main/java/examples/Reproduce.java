package examples;

import java.util.ArrayList;
import java.util.Collections;

public class Reproduce {
  public static void main(String[] args) {
    var lst = new ArrayList<String>();
    // Can't cast to a SynchronizedList
    SynchronizedList<String> syncList = (SynchronizedList<String>) Collections.synchronizedList(lst);
    new Thread(() -> {
      syncList.list.add("Hello");
    }).start();
    new Thread(() -> {
      syncList.list.add("Hello2");
    }).start();

    // Users can't access the Synchronized list since it is a private class inside the Collections class.
    // It can only be created by the Collections.synchronizedList method, and since it only returns the List interface, then we aren't able to access the public list field. 
  }
}
