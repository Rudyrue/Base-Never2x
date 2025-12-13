package funkin.objects;

import flixel.group.FlxSpriteGroup;
import funkin.objects.*;
import funkin.objects.Note.NoteData;
import funkin.objects.Strumline.StrumNote;
import haxe.ds.Vector;
import lime.app.Application;
import lime.ui.KeyCode;

class PlayField extends flixel.group.FlxSpriteGroup {
	public var mirrorStrumlines: Array<Int> = []; // A list of strumlines to mirror input to

	public var playerID(default, set):Int = 1;
	function set_playerID(value:Int):Int {
		if (playerID == value) return value;

		if (value >= strumlines.length) {
			return playerID;
		}

		for (i => line in strumlines.members) {
			line.ai = (value == i) ? botplay : true;
		}

		return playerID = value;
	}
	public var currentPlayer(get, never):Strumline;
	function get_currentPlayer():Strumline {
		if (playerID >= strumlines.length) {
			return strumlines.members[strumlines.length - 1];
		}

		return strumlines.members[playerID];
	}

	var leftSide(get, never):Strumline;
	function get_leftSide():Strumline {
		return strumlines.members[0];
	}

	var rightSide(get, never):Strumline;
	function get_rightSide():Strumline {
		return strumlines.members[1];
	}

	public var strumlines:FlxTypedSpriteGroup<Strumline>;
	var sustains:FlxTypedSpriteGroup<Sustain>;
	var notes:FlxTypedSpriteGroup<Note>;
	public var unspawnedNotes(default, null):Array<NoteData> = [];

	var notePassedIndex:Int = 0;
	var noteSpawnIndex:Int = 0;
	var noteSpawnDelay:Float = 1500;
	var sustainInterval:Float = 120;

	// excludes certain types from being included in stuff like 
	// hitsounds, note counts, etc
	public var excludeTypes:Array<String> = ['Mine'];

	public var scrollSpeed(default, set):Float = 1.0;
	function set_scrollSpeed(value:Float) {
		if (scrollSpeed == value) return scrollSpeed;

		for (obj in sustains.members) {
			if (!obj.exists) continue;
			obj.calcHeight(value);
		}
		return scrollSpeed = value;
	}

	public var downscroll:Bool = false;

	@:unreflective public var botplay(default, set):Bool = false;
	function set_botplay(value:Bool):Bool {
		return botplay = currentPlayer.ai = value;
	}

	public var rate(default, set):Float = 1.0;
	function set_rate(value:Float):Float {
		#if FLX_PITCH
		rate = rate = value;
		#else
		rate = 1.0;
		#end

		return rate;
	}

	public dynamic function noteHit(strumline:Strumline, note:Note):Void {}
	public dynamic function noteMiss(strumline:Strumline, note:Note):Void {}
	public dynamic function sustainHit(strumline:Strumline, note:Sustain, mostRecent:Bool):Void {}
	public dynamic function ghostTap(strumline:Strumline, dir:Int, shouldMiss:Bool):Void {}
	public dynamic function noteSpawned(note:Note):Void {}

	public function new(strumlineList:Array<Strumline>, ?playerID:Int = 0) {
		super();

		// really wish i wouldn't have to do this but with layering i have no choice

		// yea well in this case it looks like ASS so i kinda have to have it below
		// (ass as in psych 0.4.2 or whatever version it was 0.4 i think or 0.3
		add(sustains = new FlxTypedSpriteGroup<Sustain>());
		sustains.active = false;

		add(strumlines = new FlxTypedSpriteGroup<Strumline>());
		for (line in strumlineList) strumlines.add(line);

		add(notes = new FlxTypedSpriteGroup<Note>());
		notes.active = false;

		Application.current.window.onKeyDown.add(input);
		Application.current.window.onKeyUp.add(release);

		this.playerID = playerID;
	}

	override function destroy():Void {
		Application.current.window.onKeyDown.remove(input);
		Application.current.window.onKeyUp.remove(release);

		super.destroy();
	}

	function glowStrum(strum:StrumNote, note:Note):Bool {
		strum.playAnim('notePressed', true);
		return true;
	}

	dynamic function sustainInputs(strum:StrumNote, note:Sustain, noteSpeed:Float) {
		if (!note.wasHit || note.missed) return;

		var held:Bool = held[note.data.lane] && !note.tapHolding;
		var playerHeld:Bool = (held || note.coyoteTimer > 0);
		var heldKey:Bool = (!strum.parent.ai && playerHeld) || (strum.parent.ai && note.time <= Conductor.rawTime);

		final coyoteLim = 0.175 * note.coyoteHitMult * rate;
		if(note.coyoteTimer < coyoteLim && held){
			if (!glowStrum(strum, note))
				strum.playAnim('default', true);
		}

		note.coyoteTimer = held ? coyoteLim : note.coyoteTimer - FlxG.elapsed;
		note.coyoteAlpha = strum.parent.ai ? 1 : 0.6 + 0.4 * (note.coyoteTimer / coyoteLim);
		if (note.tapHolding && strum.parent.ai && note.coyoteTimer <= 0) {
			note.coyoteTimer = coyoteLim;
			sustainHit(strum.parent, note, true);
			glowStrum(strum, note);
		}

		final curHolds = strum.parent.curHolds;
		if (!heldKey) {
			if (!strum.parent.ai) {
				noteMiss(strum.parent, note);
				curHolds.remove(note);
				note.coyoteAlpha = 0.2;
				note.missed = true;
			}

			return;
		}

		note.timeOffset = -Math.min(note.hitTime, 0);
		note.forceHeightRecalc = true;
		strum.isHolding = true;

		if (!curHolds.contains(note)) {
			// we want the most recent, but we also dont wanna prioritize super short sustains
			final idx = note.data.length >= 250 ? curHolds.length : 0;
			curHolds.insert(idx, note);
		} else if (note.time + note.data.length <= Conductor.rawTime) {
			curHolds.remove(note);
			note.kill();
			strum.isHolding = !strum.parent.ai && held;
			if (strum.parent.ai && strum.animation.finished)
				strum.playAnim('default', true);
			note.untilTick = 0; // Hit it one last time, to make sure 
		}

		note.untilTick -= FlxG.elapsed * 1000;
		if (note.untilTick > 0 || note.tapHolding) return;

		note.untilTick = sustainInterval;
		if (strum.parent.ai || held)
			glowStrum(strum, note);
		sustainHit(strum.parent, note, curHolds[curHolds.length - 1] == note);
	}

	var keys:Array<String> = [
		'note_left',
		'note_down',
		'note_up',
		'note_right'
	];

	// to be used when unpausing.
	public function refreshInputs() {
		if (botplay) return;

		for (dir => key in keys)
			held[dir] = Controls.pressed(key);
	}

	var held:Array<Bool> = [for (_ in 0...Strumline.keyCount) false];

	function attemptNoteInput(dir:Int, strumline:Int){
		var currentPlayer = strumlines.members[strumlines.length - 1];
		if (strumline < strumlines.length)
			currentPlayer = strumlines.members[strumline];
		var currentStrum:StrumNote = currentPlayer.members[dir];
		currentStrum.isHolding = true;

		var rollHit:Bool = false;
		for (sustain in sustains.members) {
			if (!sustain.exists || !sustain.tapHolding || !sustain.wasHit || sustain.data.player != strumline || sustain.data.lane != dir) continue;

			sustain.coyoteTimer = 0.175 * sustain.coyoteHitMult * rate;
			sustainHit(currentPlayer, sustain, true);
			glowStrum(currentStrum, sustain);
			rollHit = true;
		}

		var closestDistance:Float = Math.POSITIVE_INFINITY;
		var noteToHit:Note = null;
		for (note in notes.members) {
			if (!note.exists) continue;
			if (note.data.player != strumline || !note.hittable || note.data.lane != dir) continue;
			
			var distance:Float = Math.abs(note.hitTime);
			if (distance < closestDistance) {
				closestDistance = distance;
				noteToHit = note;
			}
		}

		if (noteToHit == null) {
			if (rollHit) return;
			
			currentStrum.playAnim('pressed');
			ghostTap(currentPlayer, dir, false/*!Settings.data.ghostTapping*/);
			return;
		}

		noteHit(currentPlayer, noteToHit);
		glowStrum(currentStrum, noteToHit);
		noteToHit.kill();

		if (noteToHit.sustain != null)
			noteToHit.sustain.wasHit = true;
		noteToHit = null;
	}

	function input(id:KeyCode, _):Void {
					    // i hate this check but whatever it works
		if (botplay || (FlxG.state.subState != null && !FlxG.state.persistentUpdate)) return; 

		final dir:Int = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(id));
		if (dir == -1 || held[dir]) return;
		held[dir] = true;

		attemptNoteInput(dir, playerID);
		for(id in mirrorStrumlines)attemptNoteInput(dir, id);
	}

	inline function release(id:KeyCode, _):Void {
		if (botplay) return;

		final dir:Int = Controls.convertStrumKey(keys, Controls.convertLimeKeyCode(id));
		if (dir == -1) return;
		held[dir] = false;
		currentPlayer.members[dir].playAnim('default');
		currentPlayer.members[dir].isHolding = false;
		for (id in mirrorStrumlines) {
			if (id < strumlines.length) {
				strumlines.members[id].members[dir].playAnim('default');
				strumlines.members[id].members[dir].isHolding = false;
			}
		}
	}

	function addNote<T:Note>(data:NoteData, group:FlxTypedSpriteGroup<T>, cls:Class<T>):T {
		var strumline:Strumline = strumlines.members[data.player];

		var note:T = group.recycle(cls);
		group.remove(note, true); // keep ordering
		group.add(cast note.setup(data));

		return note;
	}

	override function update(delta:Float):Void {
		strumlines.update(delta);

		while (noteSpawnIndex < unspawnedNotes.length) {
			final noteData:NoteData = unspawnedNotes[noteSpawnIndex];
			final hitTime:Float = (noteData.time - Settings.data.noteOffset) - Conductor.rawTime;
			if (hitTime > noteSpawnDelay) break;

			var note = addNote(noteData, notes, Note);
			if (noteData.length > 0) {
				note.sustain = addNote(noteData, sustains, Sustain);
				final strum:StrumNote = strumlines.members[note.data.player].members[note.data.lane];
				final noteSpeed:Float = scrollSpeed;
				note.sustain.calcHeight(noteSpeed);
			}
			noteSpawned(note);
			noteSpawnIndex++;
		}
		
		for (obj in sustains.members) {
			if (!obj.exists) continue;

			obj.update(delta);

			final strum:StrumNote = strumlines.members[obj.data.player].members[obj.data.lane];
			final noteSpeed:Float = scrollSpeed;

			sustainInputs(strum, obj, noteSpeed);
			obj.followStrum(strum, downscroll, noteSpeed);
			obj.calcHeight(noteSpeed);

			if (obj.time + obj.data.length + 300 * rate < Conductor.rawTime)
				obj.kill();
		}

		for (obj in notes.members) {
			if (!obj.exists) continue;

			obj.update(delta);

			final strum:StrumNote = strumlines.members[obj.data.player].members[obj.data.lane];
			final noteSpeed:Float = scrollSpeed;

			obj.followStrum(strum, downscroll, noteSpeed);

			if (strum.parent.ai)
				botplayInputs(strum, obj);
			else if (!obj.missed && obj.tooLate) {
				obj.missed = true;
				noteMiss(strum.parent, obj);
				if (obj.sustain != null) {
					obj.sustain.missed = true;
					obj.sustain.multAlpha = 0.25;
				}
			}

			if (obj.time < Conductor.rawTime - 300 * rate)
				obj.kill();
		}
	}

	// ai note hitting
	function botplayInputs(strum:StrumNote, note:Note):Void {
		if (note.time > Conductor.visualTime) return;

		// normal notes
		note.wasHit = true;
		if (note.sustain != null)
			note.sustain.wasHit = true;
		note.kill();

		glowStrum(strum, note);

		noteHit(strum.parent, note);
	}

	public function load(notes:Array<NoteData>):Void {

		unspawnedNotes.resize(0);
		for (i => note in notes) {
			// there's 100% a better way of doing this
			// but idc eat my ass lol :clueless:
			// (detecting ghost notes
			if (i != 0) {
				for (evilNote in unspawnedNotes) {
					var matches:Bool = note.lane == evilNote.lane && note.player == evilNote.player;
					if (!matches || Math.abs(note.time - evilNote.time) > 2.0) continue;

					unspawnedNotes.remove(evilNote);
					evilNote.length = 0;
				}
			}

			// fixes a crash when loading a chart with only one strumline in the playfield
			note.player = Std.int(Math.min(note.player, strumlines.length - 1));
			unspawnedNotes.push(note);
		}

		unspawnedNotes.sort((a, b) -> Std.int(a.time - b.time));

		noteSpawnIndex = 0;

		this.notes.clear();

		var curIndex = noteSpawnIndex;
		var highestIdx = noteSpawnIndex;
		var highestDensity = 0;
		var sustainDensity = 0;
		var sustainDensityHigh = 0;
		while (curIndex < unspawnedNotes.length) {
			final stopAt = unspawnedNotes[curIndex].time + (noteSpawnDelay + Judgement.max.timing + 25); // add the miss window as well
			while (highestIdx < unspawnedNotes.length && unspawnedNotes[highestIdx].time <= stopAt) {
				if (unspawnedNotes[highestIdx].length > 0)
					++sustainDensity;
				++highestIdx;
			}

			final curDensity = (highestIdx - curIndex);
			highestDensity = (curDensity > highestDensity) ? curDensity : highestDensity;
			sustainDensityHigh = (sustainDensity > sustainDensityHigh) ? sustainDensity : sustainDensityHigh;
			if (highestIdx >= unspawnedNotes.length - 1) // we've reached the end, no need for more
				break;
			if (unspawnedNotes[curIndex].length > 0)
				--sustainDensity;
			++curIndex;
		}

		for (i in 0...highestDensity) {
			var newNote = new Note();
			newNote.kill();
			this.notes.add(newNote);
		}
		for (i in 0...sustainDensityHigh) {
			var newNote = new Sustain();
			newNote.kill();
			this.sustains.add(newNote);
		}
	}
}