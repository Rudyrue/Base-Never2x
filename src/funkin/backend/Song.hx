package funkin.backend;

import haxe.io.Path;
import funkin.backend.Meta;
import funkin.objects.Note;
import funkin.objects.Strumline;

typedef JsonChart = {
	var notes:Array<JsonSection>;
	var speed:Float;
}
typedef JsonSection = {sectionNotes:Array<Dynamic>, mustHitSection:Bool, ?changeBPM:Bool, ?bpm:Float, ?sectionBeats:Float, ?lengthInSteps:Float};

typedef Chart = {
	var notes:Array<NoteData>;
	var speed:Float;
	var ?meta:MetaFile;
}

class Song {
	public static function createDummyFile():Chart {
		return {
			notes: [],
			speed: 1.0
		}
	}

	public static function loadFromPath(path:String, ?meta:MetaFile):Chart {
		var file:Chart = createDummyFile();
		file.meta = meta;

		if (!FileSystem.exists(path)) return file;

		var json = cast Json.parse(File.getContent(path)).song;
		final sects:Array<JsonSection> = cast json.notes;

		if (file.meta.timingPoints == null || file.meta.timingPoints.length == 0) {
			file.meta.timingPoints ??= [];

			var curTime:Float = 0;
			var curBpm = json.bpm;
			file.meta.timingPoints.push({
				time: curTime,
				bpm: curBpm,
				beatsPerMeasure: 4
			});
			for (section in sects) {
				if (section.changeBPM == true && (section.bpm ?? 0.0) > 0) { // using == true in case theres a null changeBPM
					curBpm = section.bpm;
					file.meta.timingPoints.push({
						time: curTime,
						bpm: curBpm,
						beatsPerMeasure: 4
					});
				}

				final len = section.sectionBeats ?? ((section.lengthInSteps ?? 16) * 0.25);
				curTime += Conductor.calculateCrotchet(curBpm) * len;
			}
		}

		for (section in sects) {
			for (note in section.sectionNotes) {
				file.notes.push({
					time: Math.max(0, note[0]),
					lane: Std.int(note[1] % 4),
					length: note[2],
					player: note[1] > (Strumline.keyCount - 1) != section.mustHitSection ? 1 : 0,
					type: (note[3] is String ? note[3] : Note.defaultTypes[note[3]]) ?? '',
				});
			}
		}

		file.notes.sort((a, b) -> Std.int(a.time - b.time));

		return file;
	}

	public static function load(song:String, diff:String):Chart {
		return loadFromPath(Paths.get('songs/$song/$diff.json'), Meta.load(song));
	}

	public static function exists(song:String, difficulty:String):Bool {
		return Paths.exists('songs/$song/$difficulty.json');
	}
}