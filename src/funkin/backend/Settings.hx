package funkin.backend;

@:publicFields
@:structInit
class SaveVariables {
	// Gameplay
	var scrollSpeed:Float = 3;
	var noteOffset:Int = 0;
	var scrollDirection:String = 'Up';
	var framerate:Int = 60;
	var noteskin:String = 'arrow';

	var downscroll(get, never):Bool;
	function get_downscroll():Bool {
		return scrollDirection.toLowerCase() == 'down';
	}
}

class Settings {
	public static var data:SaveVariables = {};
	public static final default_data:SaveVariables = {};

	public static function load() {
		FlxG.save.bind('settings', Util.getSavePath());

		final fields:Array<String> = Type.getInstanceFields(SaveVariables);
		for (i in Reflect.fields(FlxG.save.data)) {
			if (!fields.contains(i)) continue;

			if (Reflect.hasField(data, 'set_$i')) Reflect.setProperty(data, i, Reflect.field(FlxG.save.data, i));
			else Reflect.setField(data, i, Reflect.field(FlxG.save.data, i));
		}

		if (FlxG.save.data.framerate == null) {
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(FlxMath.bound(refreshRate * 2, 60, 240));
		}
	}

	public static function save() {
		for (key in Reflect.fields(data)) {
			// ignores variables with getters
			if (Reflect.hasField(data, 'get_$key')) continue;
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
		}

		FlxG.save.flush();
	}

	public static function reset(?saveToDisk:Bool = false) {
		data = {};
		if (saveToDisk) save();
	}
}