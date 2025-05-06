PianoKeyboard {
	// Add this to your existing adapted code
	*new {
		^super.newCopyArgs().init
	}

	/* INITIALIZATION */
	init {}

	createUI {
		| dirt, looper |
		var window, whiteKeys, blackKeys;
		var whiteKeyWidth = 40, whiteKeyHeight = 170;
		var blackKeyWidth = 25, blackKeyHeight = 100;
		var midiOut;
		var numOctaves = 4;
		var baseNote = -24; // C4
		var keyStrokeOctave = 2;

		var whiteNoteOrder = [0, 2, 4, 5, 7, 9, 11]; // notes in an octave for white keys
		var blackOffsets = [1, 3, nil, 6, 8, 10, nil]; // nil = no black key after that white key

		var keyboardSound = "superpiano";
		var n = "0";
		var orbit = 0;
		var keyMode = "note";
		var looperPt = "rlooper";

		// Key Stroke Mapping
		var keyToWhiteIndex = (
			$a: 0, $s: 1, $d: 2, $f: 3, $g: 4, $h: 5, $j: 6
		);

		var keyToBlackIndex = (
			$w: 0, $e: 1, $t: 3, $z: 4, $u: 5
		);

		// Colors
		var whiteKeyPressedColor = Color.gray(0.8);
		var blackKeyPressedColor = Color.gray(0.4);
		var whiteKeyDefaultColor = Color.white;
		var blackKeyDefaultColor = Color.black;

		// Highlight key press
		var highlightKey = { |button, isWhite|
			button.states = [["", (isWhite.if(whiteKeyPressedColor, blackKeyPressedColor)), (isWhite.if(whiteKeyPressedColor, blackKeyPressedColor))]];
		};

		// Reset key appearance
		var resetKey = { |button, isWhite|
			button.states = [["", (isWhite.if(whiteKeyDefaultColor, blackKeyDefaultColor)), (isWhite.if(whiteKeyDefaultColor, blackKeyDefaultColor))]];
		};

		// We'll track pressed keys to simulate keyup later
		var downKeys = IdentityDictionary.new;

		var pianoView = CompositeView(window, Rect(0, 0, 200, whiteKeyHeight)).fixedWidth_(whiteKeyWidth * 7 * numOctaves).background_(Color.grey.alpha_(0.3));
		var controlView = CompositeView(window, Rect(0, 0, 50, whiteKeyHeight)).fixedWidth_(200).background_(Color.grey.alpha_(0.8));
		var recordButtonView = CompositeView(window, Rect(0, 0, 50, whiteKeyHeight)).fixedWidth_(170).background_(Color.grey.alpha_(0.8));
		var recordButton = Button.new.states_([["Record", Color.black, Color.white],["Stop Recording", Color.black, Color.red]]).fixedHeight_(140).action_({
			arg button;
			var tidalOSC = NetAddr.new("127.0.0.1", 6010);

			if (button.value == 0, {tidalOSC.sendMsg("/ctrl", "loopPt","~");});
			if (button.value == 1, {tidalOSC.sendMsg("/ctrl", "loopPt", looperPt);});
		});

		var recordingStatus = StaticText.new.string_("Not recording");

		var dirtEvent = { |note|
			var ev = (type:\dirt, dirt: dirt, s: keyboardSound.asSymbol, orbit: orbit);

			ev[keyMode.asSymbol] = note;

			if (keyMode == "note", { ev[\n] = n});

			ev.play;
		};

			controlView.layout_(
				VLayout(
					PopUpMenu.new.items_([ "Pitch (note)", "Sample bank (n)" ]).action_(
						{
							arg menu;
							if (menu.value == 0, {keyMode = "note"});
							if (menu.value == 1, {keyMode = "n"});
					}),
					HLayout(StaticText.new.string_("Sound").fixedWidth_(50), TextField.new.string_(keyboardSound).keyUpAction_({ arg val; keyboardSound = val.value;})),
					HLayout(StaticText.new.string_("Bank (n)").fixedWidth_(50), TextField.new.string_(n).keyUpAction_({ arg val; n = val.value;})),
					HLayout(StaticText.new.string_("Looper Pattern").fixedWidth_(50), TextField.new.string_(looperPt).keyUpAction_({ arg val; looperPt = val.value;})),
					HLayout(StaticText.new.string_("Orbit").fixedWidth_(50), PopUpMenu.new.items_(Array.fill(dirt.orbits.size, { arg i; i });).action_({
						arg menu;
						orbit = menu.value;
					}))
				)
			);

			recordButtonView.layout_(
				VLayout(recordButton, recordingStatus)
			);

			looper.looperStartEvent = {
				arg value;
				{
					recordingStatus.string = "Recording (" ++ value.at(\s)++ ")";
				}.defer;
			};

			looper.looperEndEvent = {
				{
					recordingStatus.string = "Not recording";
				}.defer;
			};

//ListView
//TextView

//window = Window("Piano GUI", Rect(100, 100, whiteKeyWidth * 7 * numOctaves, whiteKeyHeight)).front;

			window = Window("Piano GUI", Rect(100, 100, whiteKeyWidth * 7 * numOctaves, whiteKeyHeight+22)).front;

			window.layout_(HLayout(pianoView, controlView, recordButtonView));

// Key Strokes
			window.view.keyDownAction = { |view, char, modifiers, unicode, keycode|
				var whiteIndex = keyToWhiteIndex[char];
				var blackIndex = keyToBlackIndex[char];
				var octaveOffset = keyStrokeOctave;
				var keystrokeBaseNote = baseNote + (octaveOffset * 12);

				if (char == $l, {
					recordButton.valueAction = (recordButton.value + 1) % 2;
				});

			if (whiteIndex.notNil) {
				var i = whiteIndex;
				var note = keystrokeBaseNote + whiteNoteOrder[i];
				var guiIndex = (octaveOffset * 7) + i;
				if (downKeys[char].isNil and: { guiIndex < whiteKeys.size }) {
					whiteKeys[guiIndex].valueAction = 1;
					dirtEvent.value(note);

					highlightKey.value(whiteKeys[guiIndex], true);
					downKeys[char] = note;
				};
			} {
				if (blackIndex.notNil) {
					var i = blackIndex;
					var note = keystrokeBaseNote + blackOffsets[i];
					var guiIndex = (octaveOffset * 7) + i;
					if (downKeys[char].isNil and: { guiIndex < blackKeys.size and: blackKeys[guiIndex].notNil }) {
						blackKeys[guiIndex].valueAction = 1;
						dirtEvent.value(note);

						highlightKey.value(blackKeys[guiIndex], false);
						downKeys[char] = note;
					};
				};
			};
		};

// Key Strokes
		window.view.keyUpAction = { |view, char, modifiers, unicode, keycode|
			var octaveOffset = keyStrokeOctave;
			var note = downKeys[char];

			if (note.notNil) {
				if (keyToWhiteIndex[char].notNil) {
					var i = keyToWhiteIndex[char];
					var guiIndex = (octaveOffset * 7) + i;
					if (guiIndex < whiteKeys.size) {
						whiteKeys[guiIndex].valueAction = 0;
						resetKey.value(whiteKeys[guiIndex], true);
					};
				} {
					if (keyToBlackIndex[char].notNil) {
						var i = keyToBlackIndex[char];
						var guiIndex = (octaveOffset * 7) + i;
						if (guiIndex < blackKeys.size and: blackKeys[guiIndex].notNil) {
							blackKeys[guiIndex].valueAction = 0;
							resetKey.value(blackKeys[guiIndex], false);
						};
					};
				};
				downKeys.removeAt(char);
			};
		};


		// Draw white keys
		whiteKeys = Array.fill(numOctaves * 7, { |i|
			var note = baseNote + ((i div: 7) * 12 + whiteNoteOrder[i % 7]);
			Button(pianoView, Rect(i * whiteKeyWidth, 0, whiteKeyWidth - 1, whiteKeyHeight))
			.states_([["", Color.black, Color.white]])
			.mouseDownAction_({
				highlightKey.value(whiteKeys[i], true);  // highlight
				dirtEvent.value(note);
			})
			.mouseUpAction_({
				resetKey.value(whiteKeys[i], true);  // reset
			});
		});

// Draw black keys
		blackKeys = Array.fill(numOctaves * 7, { |i|
			var offset = blackOffsets[i % 7];
			if (offset.notNil) {
				var note = baseNote + ((i div: 7) * 12 + offset);
				var x = (i * whiteKeyWidth) + (whiteKeyWidth * 0.75) + 9;
				Button(pianoView, Rect(x - (blackKeyWidth / 2), 0, blackKeyWidth, blackKeyHeight))
				.states_([["", Color.white, Color.black]])
				.mouseDownAction_({
					highlightKey.value(blackKeys[i], false);  // highlight
					dirtEvent.value(note);
				})
				.mouseUpAction_({
					resetKey.value(blackKeys[i], false);  // reset
				})
				.canFocus_(false) // don't steal focus from white keys
			};
		});

		window.front;
	}
}


