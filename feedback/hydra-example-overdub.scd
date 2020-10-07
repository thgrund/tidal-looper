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
var hydraOSC = NetAddr("127.0.0.1", 3334);
var cycseqOSC = NetAddr("127.0.0.1", 57121);
var bufferList = List.new();
var loopCalls;

~loopCalls = loopCalls = 0;

SynthDef(\buffRecord, {|input = 0, buffer, run = 1|
	var in = SoundIn.ar(input);
	RecordBuf.ar(in, buffer, recLevel: 1.5, loop:0, run:run, doneAction: Done.freeSelf);
}).add;

synths[\loopValues] = {
	if (~lrec.isNil) {~lrec = lrec};
	if (~linput.isNil) {~linput = linput};
	if (~lname.isNil) {~lname = lname};
	if (~loopCalls.isNil) {~loopCalls = loopCalls};
};

synths[\addLoop] = {
	if (loopCalls == ~loopCalls , {
		~server.makeBundle(lat, {
			hydraOSC.sendMsg("/hydra/color", 0.2, 0.5, 0.6);
			hydraOSC.sendMsg("/hydra/brightness", 0.4);
     		cycseqOSC.sendMsg("/cycseq/message/looper", ~lname, false, (~dirt.soundLibrary.buffers[~lname.asSymbol].size));
		});
	});
};

synths[\looper] = {
	loopCalls = loopCalls + 1;

	synths[\loopValues].value;
	bufferList.add(Buffer.alloc(~dirt.server, ~dirt.server.sampleRate * (~delta.value), 1));

    ~server.makeBundle(lat, {
		recSynth = Synth(\buffRecord, [input: ~linput, buffer: bufferList @ (bufferList.size - 1) ], ~server);
		~dirt.soundLibrary.addBuffer(~lname, bufferList @ (bufferList.size - 1), true);
 		hydraOSC.sendMsg("/hydra/color", 1, 0.3, 0.2);
		hydraOSC.sendMsg("/hydra/brightness", 0.02);
		cycseqOSC.sendMsg("/cycseq/message/looper", ~lname, true, (~dirt.soundLibrary.buffers[~lname.asSymbol].size));
    });

	r = Routine {
		(~delta.value + 0.1).wait;
		synths[\addLoop].value;
	}.play;
};

synths[\loopDebugger] = { |out, lrec = 0|
	bufferList.postln;
	~delta.value.postln;
};


synths[\freeLoops] = {
	synths[\loopValues].value;
	bufferList = List.new();
	~dirt.soundLibrary.freeSoundFiles(~lname);
	cycseqOSC.sendMsg("/cycseq/message/looper", ~lname, false, 0);
};

synths.keysValuesDo{ |key, func|  ~dirt.soundLibrary.addSynth( key, (play: func)) };

)

