# TidalLooper
Looper for [SuperDirt](https://github.com/musikinformatik/SuperDirt) to provide live sampling in [TidalCycles](https://github.com/tidalcycles/Tidal).

## SuperCollider Quark

The TidalCycles looper can now be installed as SuperCollider Quark. 
Currently this has to be done manually by downloading this repository and then adding the folder in SuperCollider under `Language -> Quarks -> Install a folder`. 

This procedure has the following reasons:

- Easier to extend and customize. 
- There is a documentation in SuperCollider. 
- The looper can be loaded in the startup script when starting the server.
- Different releases can be issued in the future (but this is not done yet).

### How to use it

To start the TidalLooper you first have to create a SuperDirt instance and then initialize the TidalLooper.

```
~dirt = SuperDirt(2, s);
~looper = TidalLooper(~dirt);
```

You can adjust various parameters:
```
~looper.pLevel = 0.8;
```

In SuperCollider you can also add the TidalLooper under `File -> Open startup script` 
and have it available after every server start.

```
(
    s.waitForBoot {
        ~dirt = SuperDirt(2, s);
        // More SuperDirt ...

        // Initialize the TidalLooper
        ~looper = TidalLooper(~dirt);

        // You can adjust these parameter even in runtime
        ~looper.rLevel = 1.5;
        ~looper.pLevel = 0.8;
        ~looper.linput = 15; // Set this to your main input port.
        ~looper.lname = "mybuffer";
    }
)
```

## TidalCycles
### Pre-Requirement

First you should execute the following tidal code:

```haskell
linput = pI "linput"
lname = pS "lname"
```

Now you can use `linput` and `lname` as parameter.

### How to use it

This basic operations which are explained below is shared by all looper modes. By default 8 buffers are created, and accessible under the name 'loop' (s) and a number from 0 .. 7 (n).

The simplest form for recording is

```haskell
once $ s "looper" -- writes one cycle to the loop buffer and uses the input port 0 and the sample number 0
```

After recording you can listen back to the result with

```haskell
d1 $ s "loop"
```

It is possible to set the length of the recording (this is equals to the length of the events) i.e

```haskell
d1 $ slow 2 $ s "loop"
```

Use n to choose a specific buffer, i.e. n "2" is equal to "write to the second buffer under of the sample bank loop".

```haskell
d1 $ s "looper" # n "<0 1 2 3 4 5 6 7>"
```

And each buffer is accessible with the n function

```haskell
d2 $ s "loop" # n "[0,1,2,3,4,5,6,7]"
```

You can use each input port for recording. If you use i.e. Blackhole, than the output and input ports have the same results. This way you can write the orbit results (i.e. what came from d1) to a buffer.

```haskell
d1 $ s "looper" # linput 16
```

You can specifiy the name of your loop sample bank

``` haskell
once $ s "looper" # lname "bubu"

d1 $ s "bubu"
```

To reset all loop buffers just evaluate

```haskell
once $ s "freeLoops"
```

To persist all loop buffers of a specific buffer list just evaluate

```haskell
once $ s "persistLoops" # lname "bubu"
```

**Note 1:** I prefer to use 'qtrigger 1' to ensure, that the recording starts from the beginning of the pattern.
Maybe you want to use the looper with seqP, seqPLoop or wait.

**Note 2:** If you want to use more samples under one name, than adjust the `numBuffers` in the `Looper.scd`.

### Replace mode

In replace mode, each time the recording pattern is called, the specified buffer is recreated and any existing buffer is cleared. The basic looper `s $ "looper"` is actually the `"rlooper"` (for replace looper) and just a synonym. 

To continuously play back and record a loop, the code could looks like this

```haskell
d1 $ qtrigger 1 $ stack [
    s "rlooper" # n "<0 1 2 3>",
    s "loop" # n "[0,1,2,3]",
    s "808 cp!3"
]
```

If you record a loop of cycle length 1 and play it back at the same time, you will never hear a result, because the buffer is immediately rewritten at each cycle.

**Note:** You can change the default looper mode by changing the variable `pLevel` in the `Looper.scd`.

### Overdub mode

Loop overdub - A  mode found in many looping devices where new material can be added on top of — overdubbed on — existing loop material. This allows you to layer additional parts into a loop to create a fuller sound or a more “layered” effect. (See https://www.sweetwater.com/insync/loop-overdub/)

In overdub mode, each time the recording pattern is called, the specified buffer is kept and the incoming audio signal is mixed to the existing one. This means that no new buffer is created if a recording has already been made for that buffer. To use the looper in overdub mode you just need to use `olooper` (for overdub looper) instead of `looper`.

To continuously play back and record a loop, the code could looks like this

```haskell
d1 $ qtrigger 1 $ stack [s "olooper",s "loop",s "808 cp!3"] 
```

**Note 1:** The buffer length of a buffer is set when recording for the first time and cannot be changed afterwards (unless you clear the buffer with `s "freeLoops"`) .

**Note 2:** In an older version the additional function `playAll` was needed to simulate an overdub mode. This is no longer necessary because a "real" overdub mode was implemented.



