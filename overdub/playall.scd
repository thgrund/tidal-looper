(
~playAll = 0;

~dirt.addModule('playAll', {
	if (~playAll != 0, {
		~dirt.soundLibrary.buffers[~s].size.do({
			arg item;
			var event = ();

			event.putAll((\type: \dirt, \dirt: ~dirt ),currentEnvironment);
			currentEnvironment.postln;
			event.removeAt(\playAll);

			if (item != ~n, {
				event[\n] = item;
				event[\out] = Array.series(~dirt.numChannels, start: ~dirt.orbits[0].outBus, step: 1);
				event.play;
			});
		});
	})

}, {~playAll.notNil});

)
