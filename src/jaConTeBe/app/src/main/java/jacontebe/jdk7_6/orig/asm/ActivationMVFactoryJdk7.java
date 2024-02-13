package asm;

import org.objectweb.asm.MethodVisitor;

import edu.illinois.jacontebe.asm.MvFactory;

public class ActivationMVFactoryJdk7 implements MvFactory {

    @Override
    public MethodVisitor generateMethodVisitor(MethodVisitor mv, String name,
            String desc) {
        if (name.equals("<init>")) {
            return new AddGS2RMIConstructorVisitor(mv);
        } else if (name.equals("lookup")) {
            return new AddGS2RMILookUpMV(mv);
        }
        return mv;

    }

}
