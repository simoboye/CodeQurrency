package asm;

import javax.annotation.concurrent.ThreadSafe;

import org.objectweb.asm.MethodVisitor;

import edu.illinois.jacontebe.asm.MvFactory;

@ThreadSafe
public class NamingMVFactory implements MvFactory {

    @Override
    public MethodVisitor generateMethodVisitor(MethodVisitor mv, String name,
            String desc) {

        return new AddGS2NamingLookUpMV(mv);
    }

}
