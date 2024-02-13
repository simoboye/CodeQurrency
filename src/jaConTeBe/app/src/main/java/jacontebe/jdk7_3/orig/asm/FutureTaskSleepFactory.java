package asm;

import javax.annotation.concurrent.ThreadSafe;

import org.objectweb.asm.MethodVisitor;

@ThreadSafe
public class FutureTaskSleepFactory extends ActivationMVFactory {

    private long sleepTime;

    public FutureTaskSleepFactory(long st) {
        sleepTime = st;

    }

    @Override
    public MethodVisitor generateMethodVisitor(MethodVisitor mv, String name,
            String desc) {

        return new AddSleepMethod2FutureTaskAdapter(mv, sleepTime);
    }

}
