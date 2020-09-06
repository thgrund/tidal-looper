(
/*

This is a simple looper for TidalCycles. By default 8 buffers are created, named loop0 to loop7.
The recording status is sent as an OSC message with the structure "/cycseq/message/looper sii name, recording status, input port".

# How to use it

First you should execute the following tidal code:

linput = pI "linput"
lnr = pI "lnr"

Now you can use linput and lnr as parameter.

The simplest form for recording is
d1 $ s "loop" -- writes one cycle to the loop0 buffer and uses the input port 0

After recording u can listen back to the result with
d1 $ s "loop0"

It is possible to set the length of the recording (this is equals to the length of the cycles) i.e
d1 $ slow 2 $ s "loop"

Use lnr to choose a specific buffer. lnr 2 is equal to "write to buffer loop2".
d1 $ s "loop" # lnr "<0 1 2>"

You can use each input port for recording. If you use i.e. Blackhole, than the output and input ports have the same results. This way you can write the orbit results (i.e. what came from d1) to a buffer.

d1 $ s "loop" # linput 16

To reset all loop buffers just evaluate

once $ s "loopResetAll"

Note: I prefer to use 'trigger 1' to ensure, that the recording starts from the beginning of the pattern.
Maybe you want to use the looper with seqP, seqPLoop, wait or a specialized editor like CycSeq.

*/

var synths = ();
var recSynth;
var recording = false;
var lat = s.latency; // finetune
var maxTime = 8;
var numBuffers = 8;
var recBufs;
var lrec = 0;
var lpitch = 0;
var linput = 0;
var lname = "l";
var lnr = 0;
var r;
var cycseqOSC = NetAddr("127.0.0.1", 57121);
var recBuffers;

~recBuffers.free;
~recBuffers = recBuffers = {Buffer.alloc(~dirt.server, ~dirt.server.sampleRate * maxTime, 1)} ! numBuffers;

for(0,numBuffers-1, { |i|  ~dirt.soundLibrary.addBuffer("loop"++i, (recBuffers @ i), false )});

SynthDef(\buffRecord, {|input = 0, buffer, run = 1|
	var in = SoundIn.ar(input);
	RecordBuf.ar(in, buffer, recLevel: 1.5, loop:0, run:run, doneAction: Done.freeSelf);
}).add;

synths[\loopValues] = {
	if (~lrec.isNil) {~lrec = lrec};
	if (~lpitch.isNil) {~lpitch = lpitch};
	if (~linput.isNil) {~linput = linput};
	if (~lname.isNil) {~lname = lname};
	if (~lnr.isNil) {~lnr = lnr};
};

synths[\addLoop] = {|bufn = "loop"|

	~server.makeBundle(lat, {
		~dirt.soundLibrary.addBuffer("loop" ++ ~lnr, recBuffers @~lnr );
		cycseqOSC.sendMsg("/cycseq/message/looper", "loop" ++ ~lnr, false, ~linput);
    })
};

synths[\loop] = {
	synths[\loopValues].value;

	recBuffers[~lnr] =  Buffer.alloc(~dirt.server, ~dirt.server.sampleRate * (~delta.value), 1);

    ~server.makeBundle(lat, {
		recSynth = Synth(\buffRecord, [input: ~linput, buffer: recBuffers @ ~lnr ], ~server);
		cycseqOSC.sendMsg("/cycseq/message/looper", "loop" ++ ~lnr, true, ~linput);

    });

	r = Routine {
		(~delta.value).wait;
		recSynth.set(\run, 0);
		synths[\addLoop].value;
	}.play;
};

synths[\loopDebugger] = { |out, lrec = 0|
	synths[\loopValues].value;
	~lrec.postln;
	~lpitch.postln;
	~linput.postln;
	~lname.postln;
    ~lnr.postln;
	"".postln;
};

synths[\loopResetAll] = {
    ~recBuffers.do(_.free);
    ~recBuffers = recBuffers = { Buffer.alloc(~dirt.server, ~dirt.server.sampleRate * maxTime, 1) } ! numBuffers;
	for(0,numBuffers-1, { |i|  ~dirt.soundLibrary.addBuffer("loop"++i, (recBuffers @ i), false )});

    recording = false;
};

synths.keysValuesDo{ |key, func|  ~dirt.soundLibrary.addSynth( key, (play: func)) };

)


~recBuffers