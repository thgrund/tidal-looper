(
var synths = ();
var recSynth;
var numBuffers = 8;
var recBufs;
var linput = 0;
var lname = "loop";
var path = "~/Music/Loops/";
var loopCalls = 0;
var hydraOSC = NetAddr("127.0.0.1", 3336);
var latencyFineTuning = 0.04;

// Set the default looper mode.
// 0.0 = replace mode
// 1.0 = overdub mode
var pLevel = 0.0;
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

SynthDef(\buffRecord, {|input = 0, pLevel = 0.0, buffer|
	var in = SoundIn.ar(input);
	RecordBuf.ar(in, buffer, recLevel: 0.85, preLevel: pLevel, loop:0, run: 1, doneAction: Done.freeSelf);
}).add;

synths[\loopValues] = {
	if (~linput.isNil) {~linput = linput};
	if (~lname.isNil) {~lname = lname};
	if (~n == \none, {~n = 0.0});
	if (~loopCalls.isNil) {~loopCalls = loopCalls};
};

synths[\sendLooperStatus] = {|bufn = "loop"|
	if (loopCalls == ~loopCalls, {
		hydraOSC.sendMsg("/hydra/color", 0.2, 0.5, 0.6);
	});
};

synths[\looper] = {
	var newBuffer;
	var modN;
	var bufferEvent;

	loopCalls = loopCalls + 1;

	synths[\loopValues].value;

	modN = ~n % numBuffers;

	newBuffer = Buffer.alloc(~dirt.server, ~dirt.server.sampleRate * (~delta.value),1);

	if (~dirt.soundLibrary.buffers[~lname.asSymbol].size != numBuffers, {
		numBuffers.do({
			// Add empty buffer to access the list element later
			~dirt.soundLibrary.addBuffer(
				~lname.asSymbol,
				Buffer.alloc(~dirt.server, 0, 1),
				true
			);
		});
	});

	// Allocate new buffer with a size based on the delta value
    ~dirt.server.makeBundle(~latency + 0.01, {
		if (pLevel == 0.0, {
			// Replace mode
			if (~dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).notNil {
				~dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).free
			});

			bufferEvent = ~dirt.soundLibrary.makeEventForBuffer(newBuffer);
			~dirt.soundLibrary.buffers[~lname.asSymbol].put(modN, newBuffer);
			~dirt.soundLibrary.bufferEvents[~lname.asSymbol].put(modN, bufferEvent);
		}, {
			// Overdub mode
			if (~dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).duration == 0.0, {
				~dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).free;
				// Sorry for duplicating code here #DRY :-P
				// Maybe I will fix this later.
				bufferEvent = ~dirt.soundLibrary.makeEventForBuffer(newBuffer);
				~dirt.soundLibrary.buffers[~lname.asSymbol].put(modN, newBuffer);
				~dirt.soundLibrary.bufferEvents[~lname.asSymbol].put(modN, bufferEvent);
			});
		});


		hydraOSC.sendMsg("/hydra/color", *hydraColors[modN]);
		hydraOSC.sendMsg("/hydra/size", 0.5);

	});


	q = Routine {
		(~latency+latencyFineTuning).wait;
		recSynth = Synth(\buffRecord,
			[input: ~linput,pLevel: pLevel, buffer: ~dirt.soundLibrary.buffers[~lname.asSymbol][modN]],
			 ~dirt.server
		);
	}.play;

	r = Routine {
		(~delta.value + 0.1).wait;
		synths[\sendLooperStatus].value;
	}.play;
};

synths[\olooper] = {
	pLevel = 1.0;
	synths[\looper].value;
};

synths[\rlooper] = {
	pLevel = 0.0;
	synths[\looper].value;
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

	numBuffers.do({ |index|
		~dirt.soundLibrary.buffers[~lname.asSymbol][index].write(
			abspath ++ "/" + index ++ ".aiff"
		)
	})
};

synths.keysValuesDo{ |key, func|  ~dirt.soundLibrary.addSynth( key, (play: func)) };

)
