SynthDef(\buffRecord1, {|input = 0, pLevel = 0.0, rLevel = 1.0, buffer|
	var in = SoundIn.ar(input);
	RecordBuf.ar(in, buffer, recLevel: rLevel, preLevel: pLevel, loop:0, run: 1, doneAction: Done.freeSelf);
}).add;

SynthDef(\buffRecord2, {|input, pLevel = 0.0, rLevel = 1.0, buffer|
	var in = SoundIn.ar([0,1] + input);
	RecordBuf.ar(in, buffer, recLevel: rLevel, preLevel: pLevel, loop:0, run: 1, doneAction: Done.freeSelf);
}).add;
