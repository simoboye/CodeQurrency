package org.apache.derby.client;

import javax.annotation.concurrent.ThreadSafe;

import org.apache.derby.client.am.LogicalConnection;

@ThreadSafe
public class ConnectionSetter {

    public static void setLogicalConnection(ClientXAConnection40 connection,
            LogicalConnection logicalConnection) {
        connection.logicalConnection_ = logicalConnection;
    }
}
