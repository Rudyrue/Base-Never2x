package funkin.objects;

import flixel.graphics.frames.FlxAtlasFrames;
import funkin.objects.Strumline;
import funkin.shaders.NoteShader;

@:structInit
@:publicFields
class NoteData {
	var time:Float = 0;
	var lane:Int = 0;
	var player:Int = 0;
	var length:Float = 0.0;
	var type:String = '';
}

class Note extends FunkinSprite {
	public static var colours:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var directions:Array<String> = ['left', 'down', 'up', 'right'];
	public var data:NoteData;

	public static var colourShader:NoteShader = new NoteShader();

	public static  final defaultTypes:Array<String> = [
		'', // Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Mine',
		'No Animation'
	];

	public static var finalVertices:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0];

	public var distance:Float = 2000;

	public var rawTime(get, never):Float;
	function get_rawTime():Float return data.time;

	public var time(get, never):Float;
	function get_time():Float return rawTime - Settings.data.noteOffset;

	public var rawHitTime(get, never):Float;
	function get_rawHitTime():Float {
		return time - Conductor.rawTime;
	}

	public var hitTime(get, never):Float;
	function get_hitTime():Float {
		return time - Conductor.visualTime;
	}

	public var inHitRange(get, never):Bool;
	function get_inHitRange():Bool {
		final early:Bool = time < Conductor.rawTime + (Judgement.max.timing * earlyHitMult * Conductor.rate);
		final late:Bool = time > Conductor.rawTime - (Judgement.max.timing * lateHitMult * Conductor.rate);

		return early && late;
	}

	public var tooLate(get, never):Bool;
	function get_tooLate():Bool {
		return hitTime < -(Judgement.max.timing + 25 * Conductor.rate);
	}

	public var missed:Bool = false;
	public var wasHit:Bool = false;
	public var isSustain:Bool = false;
	public var sustain:Sustain = null;
	public var lateHitMult:Float = 1;
	public var earlyHitMult:Float = 1;
	public var multAlpha:Float = 1;
	public var sound:String = '';

	public var hittable(get, never):Bool;
	function get_hittable():Bool return exists && inHitRange && !missed;

	public var type(default, set):String;
	function set_type(value:String):String {
		type = value;
		var finalSkin:String = '';
		earlyHitMult = 1.0;
		lateHitMult = 1.0;
		sound = '';
		switch (value) {
			case 'Mine':
				finalSkin = 'mine';
				sound = 'sfx/mine';
				data.length = 0;
				earlyHitMult = 0.4;
				lateHitMult = 0.4;
				//missHealth = 20;

				active = true;
		}

		skin = finalSkin;
		return type;
	}

	public var skin(default, set):String;
	function set_skin(value:String):String {
		reload(value);
		return skin = value;
	}

	public function setup(data:NoteData):Note {
		this.data = data;
		missed = false;
		wasHit = false;
		sustain = null;
		isSustain = false;
		multAlpha = 1;
		type = data.type;

		return this;
	}

	override function update(delta:Float) {
		last.set(x, y);
		animation.update(delta);
		
		if (type == 'Mine') angle += 135 * delta;
	}

	public static function getSkin(?name:String):FlxAtlasFrames {
		name ??= '';
		if (name.length == 0) name = Settings.data.noteskin;

		return Paths.sparrowAtlas('noteSkins/$name');
	}

	public function reload(?skin:String) {
		frames = getSkin(skin);
		loadAnims(colours[data.lane]);

		scale.set(Strumline.size, Strumline.size);
		loadAnims(colours[data.lane % colours.length]);
		updateHitbox();
	}

	function loadAnims(colour:String) {
		animation.addByPrefix('default', '${colour}0');
		playAnim('default');
	}

	// custom kill handling for allowing sustain heads to stay "existant" when hit
	override public function kill():Void {
		alive = false;
		exists = false;
	}

	override public function revive():Void {
		alive = true;
		exists = true;
	}

	@:noDebug public function followStrum(strum:StrumNote, downscroll:Bool, scrollSpeed:Float) {
		visible = strum.visible && strum.parent.visible;
		distance = hitTime * 0.45 * scrollSpeed;
		distance *= downscroll ? -1 : 1;

		alpha = strum.alpha * multAlpha;
		x = strum.x;
		y = strum.y + distance;
	}

	override public function drawComplex(camera:FlxCamera) {
		_frame.prepareMatrix(_matrix, ANGLE_0, checkFlipX(), checkFlipY());
		prepareMatrix(_matrix, camera);
		camera.drawNote(_frame, _matrix, colorTransform, blend, antialiasing, false);
	}
}