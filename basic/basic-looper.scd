(
var synths = ();
var recSynth;
var lat = s.latency - 0.1; // finetune
var numBuffers = 8;
var linput = 0;
var lname = "loop";
var bufferList = List.new();

SynthDef(\buffRecord, {|input = 0, buffer|
	var in = SoundIn.ar(input);
	RecordBuf.ar(in, buffer, recLevel: 1.5, loop:0, run: 1, doneAction: Done.freeSelf);
}).add;

synths[\loopValues] = {
	if (~linput.isNil) {~linput = linput};
	if (~lname.isNil) {~lname = lname};
	if (~n == \none, {~n = 0.0});
};

synths[\looper] = {
	var newBuffer;
    var bufferEvent;
	var modN;

	synths[\loopValues].value;

	modN = ~n % numBuffers;

	bufferList.add(Buffer.alloc(~dirt.server, ~dirt.server.sampleRate * (~delta.value), 1));
    newBuffer = bufferList @ (bufferList.size - 1);

	if (~dirt.soundLibrary.buffers[~lname.asSymbol].size != numBuffers, {
		numBuffers.do({
			// Add empty buffer to access the list element later
			~dirt.soundLibrary.addBuffer(
				~lname.asSymbol,
				Buffer.alloc(~dirt.server, ~dirt.server.sampleRate, 1),
				true
			);
		});
	});

	// Allocate new buffer with a size based on the delta value
    ~server.makeBundle(lat, {
		recSynth = Synth(\buffRecord, [input: ~linput, buffer: newBuffer ], ~server);

		if (~dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).notNil,
			{~dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).free});

		bufferEvent = ~dirt.soundLibrary.makeEventForBuffer(newBuffer);

		~dirt.soundLibrary.buffers[~lname.asSymbol].put(modN, newBuffer);
		~dirt.soundLibrary.bufferEvents[~lname.asSymbol].put(modN, bufferEvent);
    });
};

synths[\loopDebugger] = {
	synths[\loopValues].value;
	~n.postln;
	~delta.value.postln;
};

synths[\freeLoops] = {
	synths[\loopValues].value;
	bufferList = List.new();
	~dirt.soundLibrary.freeSoundFiles(~lname);
};

synths.keysValuesDo{ |key, func|  ~dirt.soundLibrary.addSynth( key, (play: func)) };

)
