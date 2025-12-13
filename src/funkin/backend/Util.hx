package funkin.backend;

import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class Util {
	public inline static function openURL(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		final company:String = FlxG.stage.application.meta.get('company');
		final file:String = FlxG.stage.application.meta.get('file');

		return '${company}/${flixel.util.FlxSave.validate(file)}';
	}

	public static inline function format(string:String):String
		return string.toLowerCase().replace(' ', '-');

	// FlxStringUtil.formatBytes() but it just adds a space between the size and the unit lol
	public static function formatBytes(bytes:Float, ?precision:Int = 2):String {
		static final units:Array<String> = ["Bytes", "KB", "MB", "GB", "TB", "PB"];
		var curUnit:Int = 0;
		while (bytes >= 1024 && curUnit < units.length - 1) {
			bytes /= 1024;
			curUnit++;
		}

		return '${FlxMath.roundDecimal(bytes, precision)} ${units[curUnit]}';
	}
}
