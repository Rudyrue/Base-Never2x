package funkin.states;

import funkin.objects.Strumline;
import funkin.objects.Note;
import funkin.backend.Song.Chart;
import funkin.objects.JudgementSpr;
import funkin.objects.ComboNums;
import funkin.objects.PlayField;
import funkin.substates.PauseMenu;

class PlayState extends FunkinState {
	var playerStrums:Strumline;
	var opponentStrums:Strumline;

	public static var songID:String = 'Amusia';
	public static var song:Chart;
	public static var self:PlayState;
	var playfield:PlayField;
	var hud:FlxSpriteGroup;
	var camOther:FlxCamera;

	@:isVar public var botplay(get, set):Bool = false;
	function set_botplay(value:Bool):Bool {
		playfield.botplay = value;
		return botplay = value;
	}

	function get_botplay():Bool {
		if (playfield == null) return false;
		return playfield.botplay;
	}

	var judgeSprite:JudgementSpr;
	var comboNumbers:ComboNums;
	var combo:Int = 0;

	override function create() {
		super.create();
		self = this;

		FlxG.sound.music.stop();

		var strumlineYPos:Float = Settings.data.downscroll ? FlxG.height - 50 - Strumline.swagWidth : 50;

		camOther = FlxG.cameras.add(new FlxCamera(), false);
		camOther.bgColor.alpha = 0;

		opponentStrums = new Strumline(320, strumlineYPos);
		playerStrums = new Strumline(960, strumlineYPos, true);

		add(playfield = new PlayField([opponentStrums, playerStrums], 1));
		playfield.noteHit = noteHit;
		playfield.noteMiss = noteMiss;

		loadSong(songID);

		playfield.rate = Conductor.rate;
		playfield.scrollSpeed = Settings.data.scrollSpeed;
		playfield.scrollSpeed /= Conductor.rate;
		playfield.downscroll = Settings.data.downscroll;

		add(hud = new FlxSpriteGroup());

		hud.add(judgeSprite = new JudgementSpr(400, 300));
		hud.add(comboNumbers = new ComboNums(400, 425));

		Conductor.play();
		FlxG.mouse.visible = false;
	}

	function noteHit(strumline:Strumline, note:Note) {
		if (note.data.player != playfield.playerID) return;

		if (botplay) {
			judgeSprite.display(Judgement.list[1].timing);
			return;
		}

		var adjustedHitTime:Float = note.hitTime / playfield.rate;
		var judge:Judgement = Judgement.getFromTiming(adjustedHitTime);

/*		judge.hits++;
		score += judge.score;
		health += judge.health;
		totalNotesPlayed += judge.accuracy;
		totalNotesHit++;
		accuracy = updateAccuracy();*/

		judgeSprite.display(adjustedHitTime);
		if (judge.breakCombo) {
			//comboBreaks++;
			combo = 0;
		} else comboNumbers.display(++combo);

		if (note.sound.length > 0) FlxG.sound.play(Paths.audio(note.sound));
	}

	function noteMiss(strumline:Strumline, note:Note) {
		//score -= 10; 
		//comboBreaks++;
		combo = 0;
		//health -= 6;
		//accuracy = updateAccuracy();
	}

	/*function ghostTap(strumline:Strumline, dir:Int, shouldMiss:Bool) {
		health -= 6;
	}

	function updateAccuracy() {
		return totalNotesPlayed / (totalNotesHit + comboBreaks);
	}*/

	function loadSong(songID:String) {
		song = Song.load(songID, Difficulty.current);

		var timingPoints:Array<Conductor.TimingPoint> = [];

		Conductor.timingPoints = song.meta.timingPoints;
		Conductor.bpm = song.meta.timingPoints[0].bpm;
		Conductor.offset = song.meta.offset;
		Conductor.inst = FlxG.sound.load(Paths.audio('songs/$songID/Inst'));
		Conductor.inst.onComplete = function() endSong();

		if (song.meta.hasVocals) Conductor.vocals = FlxG.sound.load(Paths.audio('songs/$songID/Vocals'));

		playfield.load(song.notes);
	}

	public function endSong(?forceLeave:Bool = false) {
		persistentUpdate = false;
		Conductor.playing = false;

		FlxG.switchState(new TitleState());
	}

	override function update(elapsed:Float) {
		playfield.update(elapsed);
		hud.update(elapsed);

		if (FlxG.keys.justPressed.ENTER) openPauseMenu();
		if (FlxG.keys.justPressed.F8) botplay = !botplay;
	}

	override function destroy() {
		super.destroy();
		Judgement.resetHits();
		self = null;
	}

	function openPauseMenu() {
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (twn != null)
			twn.active = false);
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (tmr != null)
			tmr.active = false);

		Conductor.pause();
		persistentUpdate = false;
		openSubState(new PauseMenu());
	}
}