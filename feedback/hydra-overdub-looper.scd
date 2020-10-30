(
var synths = ();
var recSynth;
var linput = 0;
var lname = "loop";
var path = "~/Music/Loops/";
var r;
var hydraOSC = NetAddr("127.0.0.1", 3336);
var loopCalls;
~loopCalls = loopCalls = 0;

SynthDef(\buffRecord, {|input = 0, buffer, run = 1|
	var in = SoundIn.ar(input);
	RecordBuf.ar(in, buffer, recLevel: 1.5, loop:0, run:run, doneAction: Done.freeSelf);
}).add;

synths[\loopValues] = {
	if (~linput.isNil) {~linput = linput};
	if (~lname.isNil) {~lname = lname};
	if (~loopCalls.isNil) {~loopCalls = loopCalls};
};

synths[\sendLooperStatus] = {
	if (loopCalls == ~loopCalls , {
		hydraOSC.sendMsg("/hydra/color", 0.2, 0.5, 0.6);
		hydraOSC.sendMsg("/hydra/brightness", 0.4);
	});
};

synths[\looper] = {
	var buffer;
	loopCalls = loopCalls + 1;

	synths[\loopValues].value;

	buffer = Buffer.alloc(~dirt.server, ~dirt.server.sampleRate * (~delta.value), 1);

    ~dirt.server.makeBundle(~latency + 0.01, {
		recSynth = Synth(\buffRecord, [input: ~linput, buffer: buffer ], ~dirt.server);
		~dirt.soundLibrary.addBuffer(~lname.asSymbol, buffer, true);
		hydraOSC.sendMsg("/hydra/color", 1, 0.3, 0.2);
		hydraOSC.sendMsg("/hydra/brightness", 0.02);
    });

	r = Routine {
		(~delta.value + 0.1).wait;
		synths[\sendLooperStatus].value;
	}.play;
};

synths[\freeLoops] = {
	synths[\loopValues].value;
	~dirt.soundLibrary.freeSoundFiles(~lname.asSymbol);
};

synths.keysValuesDo{ |key, func|  ~dirt.soundLibrary.addSynth( key, (play: func)) };

)

