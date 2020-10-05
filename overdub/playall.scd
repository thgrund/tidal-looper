(
~playAll = 0;

~dirt.addModule('playAll', {
	if (~playAll != 0, {

		~dirt.soundLibrary.buffers[~s].size.do({
			arg item;
			var event = ();
			event.putAll((\type: \dirt, \dirt: ~dirt ), ~dirt.lastEvent);

			event.removeAt(\playAll);

			if (item != ~n, {
				event[\n] = item;
				event.play;
			});
		});
	})

}, {~playAll.notNil});

)