package asm;

import javax.annotation.concurrent.ThreadSafe;

import org.objectweb.asm.MethodVisitor;

import edu.illinois.jacontebe.asm.MvFactory;

@ThreadSafe
public class SleepMVFactory implements MvFactory {

    private long sleepTime;

    public SleepMVFactory(long st) {
        sleepTime = st;
    }

    @Override
    public MethodVisitor generateMethodVisitor(MethodVisitor mv, String name,
            String desc) {
        return new AddSleep2LoggerAdapter(mv, sleepTime);
    }
}
