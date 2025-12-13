package funkin.states;

class OptionsState extends FunkinState {
	var list:Array<Option> = [
		new Option('Scroll Speed', 'scrollSpeed', Float(0.5, 5, 0.05)),
		new Option('Note Offset', 'noteOffset', Int(-3000, 3000, 1)),
		new Option('Scroll Direction', 'scrollDirection', List(['Down', 'Up'])),
		{
			var opt = new Option('Framerate', 'framerate', Int(30, 1000, 2));
			opt.onChange = function(v) {
				FlxG.drawFramerate = FlxG.updateFramerate = v;
			}
			opt;
		},
		new Option('Note Skin', 'noteskin', List(['arrow', 'circle']))
	];

	static var curSelected:Int = 0;

	var curOption(get, never):Option;
	function get_curOption():Option return list[curSelected];

	override function create():Void {
		super.create();

		for (i in 0...list.length) {
			var option = list[i];
			var text = new FlxText(0, 0, 0, Option.getText(option), 50);
			add(text);
			option.parent = text;
		}

		changeSelection();
	}

	var curHolding:Int = 0;
	var holdWait:Float;
	override function update(delta:Float) {
		var backPressed:Bool = FlxG.keys.justPressed.ESCAPE;
		var leftJustPressed:Bool = FlxG.keys.justPressed.LEFT;
		var rightJustPressed:Bool = FlxG.keys.justPressed.RIGHT;
		var leftPressed:Bool = FlxG.keys.pressed.LEFT;
		var rightPressed:Bool = FlxG.keys.pressed.RIGHT;
		var upPressed:Bool = FlxG.keys.justPressed.UP;
		var downPressed:Bool = FlxG.keys.justPressed.DOWN;
		var acceptPressed:Bool = FlxG.keys.justPressed.ENTER;

		if (backPressed) {
			FlxG.switchState(new TitleState());
		}

		if (upPressed || downPressed || FlxG.mouse.wheel != 0) {
			var dir:Int = FlxG.mouse.wheel != 0 ? -FlxG.mouse.wheel : (upPressed ? -1 : 1);
			curSelected = FlxMath.wrap(curSelected + dir, 0, list.length - 1);
			changeSelection();
		}

		if (leftJustPressed || rightJustPressed) {
			curOption.change(leftJustPressed);
			updateOption();
			holdWait = 0.5;
		}

		if (leftPressed || rightPressed) {
			holdWait -= delta;
			if (holdWait <= 0) {
				holdWait = 0.035; // make the changing more consistent
				curOption.change(leftPressed);
				updateOption();
			}
		}

		if (acceptPressed) {
			if (curOption.type == Bool) {
				curOption.change();
				updateOption();
			}
		}
	}

	override function destroy() {
		super.destroy();
		Settings.save();
	}

	inline function updateOption() {
		curOption.parent.text = Option.getText(curOption);
	}

	function changeSelection(?change:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, list.length - 1);

		for (i => opt in list) {
			opt.parent.alpha = curSelected == i ? 1 : 0.5;
			opt.parent.y = 50 + ((i - curSelected) * 100);
		}
	}
}

enum OptionType {
	Int(min:Int, max:Int, ?inc:Int, ?wrap:Bool);
	Float(min:Float, max:Float, ?inc:Float, ?wrap:Bool);
	Bool;
	List(options:Array<String>);
	Key;
	Button;
}

class Option {
	public var parent:FlxText;
	public var name:String;
	public var type:OptionType;
	@:isVar public var value(get, set):Dynamic;
	function get_value():Dynamic {
		return Reflect.field(Settings.data, id);
	}
	function set_value(v:Dynamic):Dynamic {
		Reflect.setField(Settings.data, id, v);
		onChange(v);
		return v;
	}

	var id:String;

	//type specific
	public var powMult:Float = 1;

	public function new(name:String, id:String, type:OptionType) {
		this.name = name;
		this.id = id;
		this.type = type;

		switch type {
			// (sorry srt)
			case Float(min, max, inc, wrap):
				// add some increment specific rounding to prevent .599999999999999999999
				inc ??= 0.05;
				// my desmos graph idea of 10 ^ floor(log(x)) did not work so now i need this
				while (inc < 1) {
					inc *= 10;
					powMult *= 10;
				}
				while (inc > 9) {
					inc *= 0.1;
					powMult *= 0.1;
				}

			// do i really have to do this for every switch case that uses enums
			case _:
		}
	}

	public function change(?left:Bool) {
		switch type {
			case Bool:
				value = !value;

			case Int(min, max, inc, wrap):
				inc ??= 1;
				inc *= left ? -1 : 1;
				wrap ??= false;

				var curVal:Float = value;
				final range = (max - min);
				// fuck you too FlxMath
				curVal = wrap ? (((curVal - min) + inc + range) % range) + min : FlxMath.bound(curVal + inc, min, max);
				value = Std.int(curVal);

			case Float(min, max, inc, wrap):
				inc ??= 0.05;
				inc *= left ? -1 : 1;
				wrap ??= false;

				var curVal:Float = value;
				final range = (max - min);
				// fuck you too FlxMath
				curVal = wrap ? (((curVal - min) + inc + range) % range) + min : FlxMath.bound(curVal + inc, min, max);
				value = Math.round(curVal * powMult) / powMult;

			case List(list):
				final inc:Int = left ? -1 : 1;
				value = list[FlxMath.wrap(list.indexOf(value) + inc, 0, list.length - 1)];

			case _:
		}
	}

	public dynamic function onChange(v:Dynamic) {}

	public dynamic function formatText():String {
		var result:String = '';
		switch type {
			case Bool:
				result = value ? 'ON' : 'OFF';

			case _:
				result = '$value';
		}

		return result;
	}

	public static function getText(option:Option):String {
		var result:String = option.name;

		if (option.type == Button) return result;
		return '$result: ${option.formatText()}';
	}
}