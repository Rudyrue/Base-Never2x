class InitState extends flixel.FlxState {
	override function create():Void {
		FlxG.autoPause = false;
		FlxG.fixedTimestep = false;
		FlxG.mouse.visible = false;
		flixel.graphics.FlxGraphic.defaultPersist = true;

		Settings.load();
		FlxG.drawFramerate = FlxG.updateFramerate = Settings.data.framerate;

		FlxG.plugins.add(new funkin.backend.Conductor());
		FlxG.switchState(Type.createInstance(Main.initialState, []));
	}
}