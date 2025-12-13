package funkin;

import flixel.FlxSubState;

class FunkinSubstate extends FlxSubState {
	public function new() super();

	override function create() {
		super.create();
		Conductor.onStep.add(stepHit);
		Conductor.onBeat.add(beatHit);
		Conductor.onMeasure.add(measureHit);
	}

	override function destroy() {
		super.destroy();
		Conductor.onStep.remove(stepHit);
		Conductor.onBeat.remove(beatHit);
		Conductor.onMeasure.remove(measureHit);
	}

	public function stepHit(step:Int):Void {}
	public function beatHit(beat:Int):Void {}
	public function measureHit(measure:Int):Void {}
}
