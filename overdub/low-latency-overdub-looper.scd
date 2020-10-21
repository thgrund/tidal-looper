(
var synths = ();
var recSynth;
var maxTime = 4;
var numBuffers = 8;
var recBufs;
var linput = 0;
var lname = "loop";

SynthDef(\buffRecord, {|input = 0, buffer|
	var in = SoundIn.ar(input);
	RecordBuf.ar(in, buffer, recLevel: 1.5, loop:0, run:1, doneAction: Done.freeSelf);
}).add;

synths[\loopValues] = {
	if (~linput.isNil) {~linput = linput};
	if (~lname.isNil) {~lname = lname};
};

synths[\looper] = {
	var buffer;

	synths[\loopValues].value;

	buffer = Buffer.alloc(~dirt.server, ~dirt.server.sampleRate * (~delta.value), 1);

    ~dirt.server.makeBundle(~latency + 0.05, {
		recSynth = Synth(\buffRecord, [input: ~linput, buffer: buffer ], ~dirt.server);
		~dirt.soundLibrary.addBuffer(~lname.asSymbol, buffer, true);
    });
};

synths[\freeLoops] = {
	synths[\loopValues].value;
	~dirt.soundLibrary.freeSoundFiles(~lname.asSymbol);
};

synths.keysValuesDo{ |key, func|  ~dirt.soundLibrary.addSynth( key, (play: func)) };

)
