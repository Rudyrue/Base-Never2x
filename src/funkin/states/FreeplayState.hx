package funkin.states;

class FreeplayState extends FunkinState {
	var songList:Array<String> = [];
	var songTxtGrp:Array<FlxText> = [];

	static var curSelected:Int = 0;

	override function create():Void {
		super.create();
		loadSongs();
	}

	override function update(elapsed:Float) {
		final downJustPressed:Bool = FlxG.keys.justPressed.DOWN;

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new TitleState());
		else if (downJustPressed || FlxG.keys.justPressed.UP)
			changeSelection(downJustPressed ? 1 : -1);
		else if (FlxG.keys.justPressed.ENTER) {
			final song:String = songList[curSelected];
			PlayState.songID = song;

			FlxG.switchState(new PlayState());
		}
	}

	function changeSelection(?dir:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + dir, 0, songList.length - 1);

		for (i => text in songTxtGrp) {
			text.y = ((i - curSelected) * 100) + 50;
			text.alpha = i == curSelected ? 1 : 0.5;
		}
	}

	function loadSongs() {
		songList = FileSystem.readDirectory('assets/songs');

		for (i in 0...songList.length) {
			final txt = new FlxText(0, (i * 100) + 50, 0, songList[i], 50);
			add(txt);
			songTxtGrp.push(txt);
		}

		changeSelection();
	}
}
