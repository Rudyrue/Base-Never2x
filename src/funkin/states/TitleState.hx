package funkin.states;

class TitleState extends FunkinState {
	var list:Array<String> = ['Play', 'Options'];
	var optionGrp:FlxTypedSpriteGroup<FlxText>;
	static var curSelected:Int = 0;
	override function create():Void {
		super.create();

		playMusic();

		add(optionGrp = new FlxTypedSpriteGroup<FlxText>());

		for (i => opt in list) {
			var text = new FlxText(0, 200 + (i * 50), FlxG.width, opt, 50);
			text.alignment = 'center';
			text.screenCenter(X);
			optionGrp.add(text);
		}

		changeSelection();
	}

	override function update(delta:Float) {
		var pressedDown:Bool = FlxG.keys.justPressed.DOWN;
		if (FlxG.keys.justPressed.UP || pressedDown) {
			changeSelection(pressedDown ? 1 : -1);
		}

		if (FlxG.keys.justPressed.ENTER) {
			switch list[curSelected] {
				case 'Play':
					FlxG.switchState(new FreeplayState());

				case 'Options':
					FlxG.switchState(new OptionsState());
			}
		}
	}

	function changeSelection(?change:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, list.length - 1);

		for (i => obj in optionGrp.members) {
			obj.alpha = curSelected == i ? 1 : 0.5;
		}
	}
}