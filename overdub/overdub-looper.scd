(
var synths = ();
var recSynth;
var linput = 0;
var lname = "loop";
var path = "~/Music/Loops/";
var lat = s.latency - 0.1; // finetune

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

    ~dirt.server.makeBundle(lat, {
		recSynth = Synth(\buffRecord, [input: ~linput, buffer: buffer ], ~dirt.server);
		~dirt.soundLibrary.addBuffer(~lname.asSymbol, buffer, true);
    });
};

synths[\freeLoops] = {
	synths[\loopValues].value;
	~dirt.soundLibrary.freeSoundFiles(~lname.asSymbol);
};

synths[\persistLoops] = {
	var abspath;

	synths[\loopValues].value;

	abspath = path.standardizePath ++ ~lname.asSymbol;

	File.mkdir(abspath);

	~dirt.soundLibrary.buffers[~lname.asSymbol].size.do({ |index|
		~dirt.soundLibrary.buffers[~lname.asSymbol][index].write(
			abspath ++ "/" + index ++ ".aiff"
		)
	})
};

synths.keysValuesDo{ |key, func|  ~dirt.soundLibrary.addSynth( key, (play: func)) };

)
