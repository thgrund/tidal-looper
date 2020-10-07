# Basic looper

## Pre-Requirement

First you should execute the following tidal code:

```
linput = pI "linput"
```

Now you can use `linput` and `lnr` as parameter.

## How to use it

This basic operations which are explained below is shared by all looper variants. By default 8 buffers are created, and accessible under the name 'loop' (s) and a number from 0 .. 7 (n).

The simplest form for recording is

```
once $ s "looper" -- writes one cycle to the loop buffer and uses the input port 0 and the sample number 0
```

After recording u can listen back to the result with

```
d1 $ s "loop"
```

It is possible to set the length of the recording (this is equals to the length of the events) i.e

```
d1 $ slow 2 $ s "loop"
```

Use n to choose a specific buffer, i.e. n "2" is equal to "write to the second buffer under of the sample bank loop".

```
d1 $ s "looper" # n "<0 1 2 3 4 5 6 7>"
```

And each buffer is accessible with the n function

```
d2 $ s "loop" # n "[0,1,2,3,4,5,6,7]"
```

You can use each input port for recording. If you use i.e. Blackhole, than the output and input ports have the same results. This way you can write the orbit results (i.e. what came from d1) to a buffer.

```
d1 $ s "looper" # linput 16
```

You can specifiy the name of your loop sample bank

``` 
once $ s "looper" # lname "bubu"

d1 $ s "bubu"
```

To continuously play back and record a loop, the code looks like this

```
d1 $ qtrigger 1 $ stack [
    s "looper" # n "<0 1 2 3>" # linput 14,
    s "loop" # n "[0,1,2,3]"
]
```

If you want to use more samples under one name, than adjust the `numBuffers` in the basic-looper.scd.

To reset all loop buffers just evaluate

```
once $ s "freeLoops"
```

Note: I prefer to use 'qtrigger 1' to ensure, that the recording starts from the beginning of the pattern.
Maybe you want to use the looper with seqP, seqPLoop or wait.
