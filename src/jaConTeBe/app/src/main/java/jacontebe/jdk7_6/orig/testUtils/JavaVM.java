package testUtils;

/*
 * Copyright (c) 1998, 2006, Oracle and/or its affiliates. All rights reserved.
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
 *
 */

import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.util.StringTokenizer;

import javax.annotation.concurrent.ThreadSafe;

/**
 * RMI regression test utility class that uses Runtime.exec to spawn a java
 * process that will run a named java class.
 * 
 * Option "-Xbootclasspath/p:" to load a modified sun.rmi.server.Activation.java
 * instead the original one from rt.jar is added.
 * 
 * @Modified by Ziyi Lin
 */
@ThreadSafe
public class JavaVM {

    // need to
    protected Process vm = null;

    private String classname = "";
    private String args = "";
    private String options = "";
    private OutputStream outputStream = System.out;
    private OutputStream errorStream = System.err;
    private String policyFileName = null;

    /** string name of the program execd by JavaVM */
    private static String javaProgram = "java";

    static {
        try {
            javaProgram = TestLibrary.getProperty("java.home", "")
                    + File.separator + "bin" + File.separator + javaProgram;
        } catch (SecurityException se) {
        }
    }

    public JavaVM(String classname) {
        this.classname = classname;
    }

    public JavaVM(String classname, String options, String args) {
        this.classname = classname;
        this.options = options;
        this.args = args;
    }

    public JavaVM(String classname, String options, String args,
            OutputStream out, OutputStream err) {
        this(classname, options, args);
        this.outputStream = out;
        this.errorStream = err;
    }

    public void addOptions(String[] opts) {
        String newOpts = "";
        for (int i = 0; i < opts.length; i++) {
            newOpts += " " + opts[i];
        }
        newOpts += " ";
        options = newOpts + options;
    }

    public void addArguments(String[] arguments) {
        String newArgs = "";
        for (int i = 0; i < arguments.length; i++) {
            newArgs += " " + arguments[i];
        }
        newArgs += " ";
        args = newArgs + args;
    }

    public void setPolicyFile(String policyFileName) {
        this.policyFileName = policyFileName;
    }

    /**
     * This method is used for setting VM options on spawned VMs. It returns the
     * extra command line options required to turn on jcov code coverage
     * analysis.
     */
    protected static String getCodeCoverageOptions() {
        return TestLibrary.getExtraProperty("jcov.options", "");
    }

    /**
     * Exec the VM as specified in this object's constructor.
     */
    public void start(String loc) throws IOException {

        if (vm != null)
            return;

        /*
         * If specified, add option for policy file
         */
        if (policyFileName != null) {
            String option = "-Djava.security.policy=" + policyFileName;
            addOptions(new String[] { option });
        }
        /*
         * These options are for remote debug usage. String debugOption=
         * " -Xdebug -Xrunjdwp:transport=dt_socket,address=8001,server=y,suspend=y "
         * ; addOptions(new String[]{debugOption});
         */

        // This option is to load a modified sun.rmi.server.Activation.java
        // instead the original one from rt.jar.
        // The modified one increases window for buggy interleaving. So the bug
        // will be reproduced easier.

        String debugOption = "-Xbootclasspath/p:" + loc + "/classes ";
        addOptions(new String[] { debugOption });
        addOptions(new String[] { getCodeCoverageOptions() });

        StringTokenizer optionsTokenizer = new StringTokenizer(options);
        StringTokenizer argsTokenizer = new StringTokenizer(args);
        int optionsCount = optionsTokenizer.countTokens();
        int argsCount = argsTokenizer.countTokens();

        String javaCommand[] = new String[optionsCount + argsCount + 2];
        int count = 0;

        javaCommand[count++] = JavaVM.javaProgram;
        while (optionsTokenizer.hasMoreTokens()) {
            javaCommand[count++] = optionsTokenizer.nextToken();
        }
        javaCommand[count++] = classname;
        while (argsTokenizer.hasMoreTokens()) {
            javaCommand[count++] = argsTokenizer.nextToken();
        }

        // mesg("command = " + Arrays.asList(javaCommand).toString());
        System.err.println("");

        vm = Runtime.getRuntime().exec(javaCommand);

        /* output from the execed process may optionally be captured. */
        StreamPipe.plugTogether(vm.getInputStream(), this.outputStream);
        StreamPipe.plugTogether(vm.getErrorStream(), this.errorStream);

        try {
            Thread.sleep(2000);
        } catch (Exception ignore) {
        }

        // mesg("finished starting vm.");
    }

    public void destroy() {
        if (vm != null) {
            vm.destroy();
        }
        vm = null;
    }

    protected Process getVM() {
        return vm;
    }
}
