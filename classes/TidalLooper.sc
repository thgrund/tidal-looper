TidalLooper {

	var dirt;

	var <>lname = "loop", <>linput = 0;
	var <>channels = 1;
	var <>pLevel = 1.0, <>rLevel = 1.0; //replace behaviour
	var <>numBuffers = 8;
	var <>looperSynth = 'buffRecord';
	var <>persistPath = "~/Music/Loops/";
	var <>latencyFineTuning = 0.04;
	var currentCycleValues, currentRecordSynth, currentInput, currentChannels;
	var loopCalls = 0;

	classvar internalPLevel = 0.0;

	*new { |dirt|
		^super.newCopyArgs(dirt).init
	}

	init {
		if ( (dirt.isNil == true), {
			"No dirt instance was passed. Abort tidal looper initialization.".postln;
		}, {
			"".postln;
			"---- initialize TidalLooper ----".postln;

			this.loadSynthDefs;

			this.createLooperFunctions.keysValuesDo{ |key, func|
				("function " ++ key ++ " was successfully loaded.").postln;
				dirt.soundLibrary.addSynth( key, (play: func));
			};

			currentCycleValues = [];
		});
   }

	loadSynthDefs { |path|
		var filePaths;
		path = path ?? { "../synths".resolveRelative };
		filePaths = pathMatch(standardizePath(path +/+ "*"));
		filePaths.do { |filepath|
			if(filepath.splitext.last == "scd") {
				(dirt:this).use { filepath.load }; "loading synthdefs in %\n".postf(filepath)
			}
		}
	}

	mapTidalParameter {
		if (~linput.isNil) {~linput = linput};
		if (~lname.isNil) {~lname = lname};
		if (~n == \none, {~n = 0.0});
		if (~loopCalls.isNil) {~loopCalls = loopCalls};
	}

	createLooperFunctions {
		var synths = ();

		synths[\looper] = {
			var newBuffer;
			var modN;
			var bufferEvent;
			var currentValueDict = Dictionary.newFrom(currentCycleValues);
			var inputChannels;

			if (~linput.isNil, {
				currentInput = linput;
			}, {
				currentInput = ~linput;
			});

			if (~channels.isNil, {
				currentChannels = channels;
			}, {
				currentChannels = ~channels;
			});

			inputChannels = Array.series(currentChannels,currentInput,1);

			loopCalls = loopCalls + 1;

			this.mapTidalParameter;

			modN = ~n % numBuffers;

			newBuffer = Buffer.alloc(dirt.server, dirt.server.sampleRate * (~delta.value),currentChannels);

			if (dirt.soundLibrary.buffers[~lname.asSymbol].size != numBuffers, {
				numBuffers.do({
					// Add empty buffer to access the list element later
					dirt.soundLibrary.addBuffer(
						~lname.asSymbol,
						Buffer.alloc(dirt.server, 0, currentChannels),
						true
					);
				});
			});

			// Allocate new buffer with a size based on the delta value
			dirt.server.makeBundle(~latency + 0.01, {

				if (internalPLevel == 0.0, {
					// Replace mode
					if (dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).notNil {
						dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).free
					});

					bufferEvent = dirt.soundLibrary.makeEventForBuffer(newBuffer);
					bufferEvent[\notYetRead] = false;
					dirt.soundLibrary.buffers[~lname.asSymbol].put(modN, newBuffer);
					dirt.soundLibrary.bufferEvents[~lname.asSymbol].put(modN, bufferEvent);
				}, {
					// Overdub mode
					if (dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).duration == 0.0, {
						dirt.soundLibrary.buffers[~lname.asSymbol].at(modN).free;
						// Sorry for duplicating code here #DRY :-P
						// Maybe I will fix this later.
						bufferEvent = dirt.soundLibrary.makeEventForBuffer(newBuffer);
						bufferEvent[\notYetRead] = false;
						dirt.soundLibrary.buffers[~lname.asSymbol].put(modN, newBuffer);
						dirt.soundLibrary.bufferEvents[~lname.asSymbol].put(modN, bufferEvent);
					});
				});
			});

			Routine {
				(~latency+latencyFineTuning).wait;
				Synth((looperSynth ++ currentChannels).asSymbol,
					[input: inputChannels, pLevel: internalPLevel, rLevel: this.rLevel, buffer: dirt.soundLibrary.buffers[~lname.asSymbol][modN]],
					dirt.server
				);
			}.play;

			Routine {
			    (~delta.value + 0.1).wait;
			}.play;
		};

		synths[\olooper] = {
			internalPLevel = pLevel;
			synths[\looper].value;
		};

		synths[\rlooper] = {
			internalPLevel = 0.0;
			synths[\looper].value;
		};

		synths[\freeLoops] = {
			this.mapTidalParameter;
			dirt.soundLibrary.freeSoundFiles(~lname.asSymbol);
		};

		^synths;
	}

	freeLoops { | lname = "loop" |
		this.mapTidalParameter;
		dirt.soundLibrary.freeSoundFiles(lname.asSymbol);
	}

	persistLoops { | lname = "loop" |
		var abspath;

		this.mapTidalParameter;

		abspath = this.persistPath.standardizePath ++ lname.asSymbol;

		File.mkdir(abspath);

		numBuffers.do({ |index|
			dirt.soundLibrary.buffers[lname.asSymbol][index].write(
				abspath ++ "/" + index ++ ".aiff"
			)
		})
	}

}

