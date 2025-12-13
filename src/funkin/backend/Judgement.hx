package funkin.backend;

@:structInit
class Judgement {
	public static var list:Array<Judgement> = [
		// for fnf sake i'll just remove it
/*		{
			name: 'marv', 
			timing: 22.5, 
			accuracy: 100, 
			health: 2.5
		},*/
		{
			name: 'sick', 
			timing: 45, 
			accuracy: 100, 
			health: 2.5
		},
		{
			name: 'good', 
			timing: 90, 
			accuracy: 85,
			health: 1
		},
		{
			name: 'bad', 
			timing: 135, 
			accuracy: 45,
			health: -6
		},
		{
			name: 'shit', 
			timing: 180, 
			accuracy: 30, 
			health: -10,
			breakCombo: true
		}
	];

	public var timing:Float = 0;
	public var accuracy:Float = 0;
	public var health:Float = 0;
	public var score:Int = 0;
	public var name:String = '';
	public var hits:Int = 0;
	public var breakCombo:Bool = false;

	public static var max(get, never):Judgement;
	static function get_max():Judgement return list[list.length - 1];

	public static var min(get, never):Judgement;
	static function get_min():Judgement return list[0];

	inline public static function resetHits():Void {
		for (judge in list) judge.hits = 0;
	}

	public static function getIDFromTiming(noteDev:Float):Int {
		var value:Int = list.length - 1;

		for (i in 0...list.length) {
			if (Math.abs(noteDev) > list[i].timing) continue;
			value = i;
			break;
		}

		return value;
	}

	public static function getFromTiming(noteDev:Float):Judgement {
		var judge:Judgement = max;

		for (possibleJudge in list) {
			if (Math.abs(noteDev) > possibleJudge.timing) continue;
			judge = possibleJudge;
			break;
		}

		return judge;
	}
}