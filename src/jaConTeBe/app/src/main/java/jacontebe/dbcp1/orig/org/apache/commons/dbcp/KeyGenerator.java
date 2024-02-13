package org.apache.commons.dbcp;

import static org.mockito.Mockito.mock;

import javax.annotation.concurrent.ThreadSafe;

import org.apache.commons.dbcp.PoolingConnection.PStmtKey;

@ThreadSafe
public class KeyGenerator {

    public static PStmtKey generateKey() {
        PStmtKey key = mock(PStmtKey.class);
        return key;
    }
}
