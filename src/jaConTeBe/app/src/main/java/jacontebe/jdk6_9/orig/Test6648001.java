/*
 * Copyright (c) 2010, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */

/**
 * @test
 * @bug 6648001
 * @run main/othervm/timeout=20 -ea:sun.net.www.protocol.http.AuthenticationInfo -Dhttp.auth.serializeRequests=true Deadlock
 * @summary  canceling HTTP authentication causes deadlock
 */

import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.InetSocketAddress;
import java.net.PasswordAuthentication;
import java.net.URL;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import javax.annotation.concurrent.ThreadSafe;

import com.sun.net.httpserver.BasicAuthenticator;
import com.sun.net.httpserver.Headers;
import com.sun.net.httpserver.HttpContext;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpPrincipal;
import com.sun.net.httpserver.HttpServer;

import edu.illinois.jacontebe.Helpers;
import edu.illinois.jacontebe.OptionHelper;
import edu.illinois.jacontebe.framework.Reporter;

/**
 * Bug URL: https://bugs.openjdk.java.net/browse/JDK-6648001
 * This is a wait-notify deadlock. 
 * Reproduce environment: JDK 1.6.0, fixed since jdk 1.6.0_10 
 * 
 * Run this test with VMoptions -ea:sun.net.www.protocol.http.AuthenticationInfo
 * -Dhttp.auth.serializeRequests=true
 * 
 * Options:
 * --monitoroff, -mo : Turn deadlock monitor off. When
 *            monitor is turned on, it reports the deadlock message and stop the
 *            program.
 *            
 * @collector Ziyi Lin
 */
@ThreadSafe
public class Test6648001 {

    public static void main(String[] args) throws Exception {
        int timeout = 30;
        Reporter.reportStart("jdk6648001", timeout, "wait-notify deadlock");
        Reporter.printWarning(null, "1.6.0_10", null);
        if (!OptionHelper.optionParse(args)) {
            return;
        }
        Helpers.startWaitingMonitor(timeout, "ServerRunner-0", "ServerRunner-1");
        Handler handler = new Handler();
        InetSocketAddress addr = new InetSocketAddress(0);
        HttpServer server = HttpServer.create(addr, 0);
        HttpContext ctx = server.createContext("/test", handler);
        BasicAuthenticator a = new BasicAuthenticator("foobar@test.realm") {
            @Override
            public boolean checkCredentials(String username, String pw) {
                return "fred".equals(username) && pw.charAt(0) == 'x';
            }
        };

        ctx.setAuthenticator(a);
        ExecutorService executor = Executors.newCachedThreadPool();
        server.setExecutor(executor);
        server.start();
        java.net.Authenticator.setDefault(new MyAuthenticator());

        Thread[] ts = new Thread[2];
        for (int i = 0; i < 2; i++) {
            ts[i] = new Runner(server, i);
            ts[i].start();
            // t.join();
        }
        for (int i = 0; i < 2; i++) {
            ts[i].join();
        }
        server.stop(2);
        executor.shutdown();

        if (error) {
            throw new RuntimeException("test failed error");
        }

        if (count != 2) {
            throw new RuntimeException("test failed count = " + count);
        }
        Reporter.reportEnd(false);

    }

    static class Runner extends Thread {
        HttpServer server;
        int i;

        Runner(HttpServer s, int i) {
            server = s;
            this.i = i;
            setName("ServerRunner-" + i);
        }

        @Override
        public void run() {
            URL url;
            HttpURLConnection urlc;
            try {
                url = new URL("http://localhost:"
                        + server.getAddress().getPort() + "/test/foo.html");
                urlc = (HttpURLConnection) url.openConnection();
            } catch (IOException e) {
                error = true;
                return;
            }
            InputStream is = null;
            try {
                is = urlc.getInputStream();
                while (is.read() != -1) {
                }
            } catch (IOException e) {
                if (i == 1)
                    error = true;
            } finally {
                if (is != null)
                    try {
                        is.close();
                    } catch (IOException e) {
                    }
            }
        }
    }

    public static boolean error = false;
    public static int count = 0;

    static class MyAuthenticator extends java.net.Authenticator {
        @Override
        public PasswordAuthentication getPasswordAuthentication() {
            PasswordAuthentication pw;
            if (!getRequestingPrompt().equals("foobar@test.realm")) {
                Test6648001.error = true;
            }
            if (count == 0) {
                pw = null;
            } else {
                pw = new PasswordAuthentication("fred", "xyz".toCharArray());
            }
            count++;
            return pw;
        }
    }

    static class Handler implements HttpHandler {
        int invocation = 1;

        @Override
        public void handle(HttpExchange t) throws IOException {
            InputStream is = t.getRequestBody();
            Headers map = t.getRequestHeaders();
            Headers rmap = t.getResponseHeaders();
            while (is.read() != -1)
                ;
            is.close();
            t.sendResponseHeaders(200, -1);
            HttpPrincipal p = t.getPrincipal();
            if (!p.getUsername().equals("fred")) {
                error = true;
            }
            if (!p.getRealm().equals("foobar@test.realm")) {
                error = true;
            }
            t.close();
        }
    }
}
