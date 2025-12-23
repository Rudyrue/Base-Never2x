package funkin;

class FunkinState extends FlxState {
	override function create() {
		Paths.clearUnusedMemory();

		Conductor.reset();

		Conductor.onStep.add(stepHit);
		Conductor.onBeat.add(beatHit);
		Conductor.onMeasure.add(measureHit);

		super.create();

		// I LOVE OPENFL.DISPLAY.SPRITE.FILLRECT();
		FlxG.camera.bgColor.alpha = 0;
	}

	public function stepHit(step:Int):Void {}
	public function beatHit(beat:Int):Void {}
	public function measureHit(measure:Int):Void {}

	function playMusic() {
		if (FlxG.sound.music != null && FlxG.sound.music.active) return;

		FlxG.sound.playMusic(Paths.music("it felt weird having the build be quiet so here's a random song"), 1, true);
	}
}
