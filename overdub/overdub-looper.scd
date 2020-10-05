(
var synths = ();
var recSynth;
var recording = false;
var lat = s.latency - 0.1; // finetune
var maxTime = 4;
var numBuffers = 8;
var recBufs;
var lrec = 0;
var linput = 0;
var lname = "loop";
var r;
var bufferList = List.new();

SynthDef(\buffRecord, {|input = 0, buffer, run = 1|
	var in = SoundIn.ar(input);
	RecordBuf.ar(in, buffer, recLevel: 1.5, loop:0, run:run, doneAction: Done.freeSelf);
}).add;

synths[\loopValues] = {
	if (~lrec.isNil) {~lrec = lrec};
	if (~linput.isNil) {~linput = linput};
	if (~lname.isNil) {~lname = lname};
};

synths[\looper] = {
	synths[\loopValues].value;
	bufferList.add(Buffer.alloc(~dirt.server, ~dirt.server.sampleRate * (~delta.value), 1));

    ~server.makeBundle(lat, {
		recSynth = Synth(\buffRecord, [input: ~linput, buffer: bufferList @ (bufferList.size - 1) ], ~server);
		~dirt.soundLibrary.addBuffer(~lname, bufferList @ (bufferList.size - 1), true);
    });
};

synths[\loopDebugger] = { |out, lrec = 0|
	bufferList.postln;
	~delta.value.postln;
};


synths[\freeLoops] = {
	synths[\loopValues].value;
	bufferList = List.new();
	~dirt.soundLibrary.freeSoundFiles(~lname);
};

synths.keysValuesDo{ |key, func|  ~dirt.soundLibrary.addSynth( key, (play: func)) };

)
