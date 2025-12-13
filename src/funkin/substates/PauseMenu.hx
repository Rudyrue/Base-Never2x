package funkin.substates;

class PauseMenu extends FunkinSubstate {
	final list:Array<String> = ['Resume', 'Restart', 'Options', 'Exit'];

	var piss:FlxTypedSpriteGroup<FlxText>;

	public var curSelected:Int = 0;

	var music:FlxSound;

	override function create() {
		super.create();

		final bgSpr = new FunkinSprite();
		bgSpr.makeGraphic(1, 1, FlxColor.BLACK);
		bgSpr.scale.set(FlxG.width, FlxG.height);
		bgSpr.updateHitbox();
		bgSpr.screenCenter();
		bgSpr.alpha = 0.6;
		add(bgSpr);

		add(piss = new FlxTypedSpriteGroup<FlxText>());

		for (i in 0...list.length) {
			final txt = new FlxText(0, 50 + (i * 100), list[i], 100);
			txt.alignment = 'center';
			txt.screenCenter(X);
			piss.add(txt);
		}

		changeSelection();
	}

	override function update(elapsed:Float) {
		final downJustPressed:Bool = FlxG.keys.justPressed.DOWN;

		if (downJustPressed || FlxG.keys.justPressed.UP)
			changeSelection(downJustPressed ? 1 : -1);

		if (FlxG.keys.justPressed.ENTER) {
			switch list[curSelected] {
				case 'Resume':
					close();
					Conductor.resume();
				case 'Restart':
					FlxG.resetState();
				case 'Options':
					FlxG.switchState(new funkin.states.OptionsState());
				case 'Exit':
					FlxG.switchState(new TitleState());
			}
		}
	}

	function destroyMusic()
	{
		/*if (music == null || !music.exists) return;

			FlxG.sound.list.remove(music);

			music.stop();
			music.kill();
			music.destroy();
			music = null; */
	}

	override function destroy() {
		destroyMusic();

		super.destroy();
		FlxTween.globalManager.forEach(function(twn:FlxTween) if (twn != null)
			twn.active = true);
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (tmr != null)
			tmr.active = true);
	}

	function changeSelection(?change:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, piss.length - 1);

		for (i => fuck in piss.members) {
			fuck.alpha = i == curSelected ? 1 : 0.5;
		}
	}
}
