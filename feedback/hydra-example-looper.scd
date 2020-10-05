(
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