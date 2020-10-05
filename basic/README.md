# Basic looper

## Pre-Requirement

First you should execute the following tidal code:

```
linput = pI "linput"
lnr = pI "lnr"
```

Now you can use `linput` and `lnr` as parameter.

## How to use it

This basic operations which are explained below is shared by all Looper variants. By default 8 buffers are created, named loop0 to loop7.

The simplest form for recording is

```
d1 $ s "loop" -- writes one cycle to the loop0 buffer and uses the input port 0
```

After recording u can listen back to the result with

```
d1 $ s "loop0"
```

It is possible to set the length of the recording (this is equals to the length of the events) i.e

```
d1 $ slow 2 $ s "loop"
```

Use lnr to choose a specific buffer. lnr 2 is equal to "write to buffer loop2".

```
d1 $ s "loop" # lnr "<0 1 2>"
```

You can use each input port for recording. If you use i.e. Blackhole, than the output and input ports have the same results. This way you can write the orbit results (i.e. what came from d1) to a buffer.

```
d1 $ s "loop" # linput 16
```

To reset all loop buffers just evaluate

```
once $ s "loopResetAll"
```

Note: I prefer to use 'trigger 1' to ensure, that the recording starts from the beginning of the pattern.
Maybe you want to use the looper with seqP, seqPLoop, wait or a specialized editor like CycSeq.