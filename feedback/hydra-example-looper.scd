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

It is possible to set the length of the recording (this is equals to the length of the events) i.e
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
var lat = s.latency - 0.1; // finetune
var maxTime = 4;
var numBuffers = 8;
var recBufs;
var lrec = 0;
var lpitch = 0;
var linput = 0;
var lname = "l";
var lnr = 0;
var r;
var hydraOSC = NetAddr("127.0.0.1", 3336);
var recBuffers;
var loopCalls;

var hydraColors = List[
	[1, 0.3, 0.2],
	[1, 0.1, 0.3],
	[1, 0.5, 0.3],
	[1, 0.6, 0.2],
	[1, 0.6, 0.6],
	[1, 0, 0.6],
	[1, 0.7, 0],
	[0.9, 0.8, 0.8]
];

~recBuffers.free;
~recBuffers = recBuffers = {Buffer.alloc(~dirt.server, ~dirt.server.sampleRate * maxTime, 1)} ! numBuffers;

~recording = false;
~loopCalls = loopCalls = 0;

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
	if (~loopCalls.isNil) {~loopCalls = loopCalls};
};

synths[\addLoop] = {|bufn = "loop"|
	if (loopCalls == ~loopCalls , {
		~server.makeBundle(lat, {
			hydraOSC.sendMsg("/hydra/color", 0.2, 0.5, 0.6);
			hydraOSC.sendMsg("/hydra/brightness", 0.4);
		});
	});
};

synths[\loop] = {
    loopCalls = loopCalls + 1;

	synths[\loopValues].value;
	recBuffers[~lnr] =  Buffer.alloc(~dirt.server, ~dirt.server.sampleRate * (~delta.value), 1);

    ~server.makeBundle(lat, {
		recSynth = Synth(\buffRecord, [input: ~linput, buffer: recBuffers @ ~lnr ], ~server);
		~dirt.soundLibrary.addBuffer("loop" ++ ~lnr, recBuffers @~lnr );
		~recording = true;
		hydraOSC.sendMsg("/hydra/color", *hydraColors[~lnr]);
		hydraOSC.sendMsg("/hydra/brightness", 0.02);
    });

	r = Routine {
		(~delta.value + 0.1).wait;
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