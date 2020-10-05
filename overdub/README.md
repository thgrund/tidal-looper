# Looper to simulate overdub mode

Loop overdub - A  mode found in many looping devices where new material can be added on top of — overdubbed on — existing loop material. This allows you to layer additional parts into a loop to create a fuller sound or a more “layered” effect. (See https://www.sweetwater.com/insync/loop-overdub/)

## Pre-Requirement

In TidalCycles version 1.6.2 the function `pB` is currently missing to create own Pattern Bool functions. But this is necessary to use the `playAll` function (is introduced below) which simulates an overdub mode.

```
pB :: String -> Pattern Bool -> ControlPattern
pB name = fmap (Map.singleton name . (flip VB) Nothing)
```

A PR has already been created for this and the `pB` function will certainly be available in a future version of TidalCycles  https://github.com/tidalcycles/Tidal/pull/727

You should execute the following tidal code (or append it to you BootTidal.hs) for using `linput`, `lname` and `playAll` as parameter.

```-- Params
linput = pI "linput"
lname = pS "lname"
playAll = pB "playAll"
```

And you should execute the SuperCollider code under `playall.scd` to get access to the playAll effect. 

## How to use it

This looper differs from the basic looper type in that all samples are appended to a named sample bank, so you can access it with the n function.

The simplest form of recording is:

``` 
d1 $ s "looper" -- default linput = 0 and lname = "loop"
```

After recording you can listen back to the result with

```
d2 $ s "loop"
```

You can use each input port for recording. If you use i.e. Blackhole, than the output and input ports have the same results. This way you can write the orbit results (i.e. what came from d1) to a buffer.

```
d1 $ s "looper" # linput "14"
```

And you can specify a looper name. In this way you can switch between different sample names and append as many loops as you want.

```
d1 $ s "looper" # linput "14" # lname "bubu"
```

Play them back with `playAll` - all buffers under sample name `loop` will be played immediately in parallel. In this way you can easily append a new loop and it will be played with the other loops.  No further code needs to be written for this. This simulates some kind of overdub mode.

```
d2 $ playAll "t" # s "loop"
```

But the huge advantage here is, that you can access each sample and switch between a single sample (or composition) with the `playAll` and `n` function.

```
d2 $ playAll "<t! f>" # n "<0 1 2 3>" # s "loop"
```

Use the `freeLoops` function to free all loops under a specific sample name.

```
once $ s "freeLoops" # lname "loops"
```



