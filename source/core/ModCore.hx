package core;

import flixel.FlxG;
import openfl.Lib;
#if FUTURE_POLYMOD
import polymod.Polymod;
import polymod.Polymod.ModMetadata;
import polymod.Polymod.PolymodError;
import polymod.backends.PolymodAssets.PolymodAssetType;
import polymod.format.ParseRules;
#end

/**
 * Class based originally from ChainSaw Engine.
 * Credits: MAJigsaw77.
 */
class ModCore
{
	private static final API_VER:String = '1.0.0';
	private static final MOD_DIR:String = 'mods';

	#if FUTURE_POLYMOD
	private static final extensions:Map<String, PolymodAssetType> = [
		'ogg' => AUDIO_GENERIC,
		'mp3' => AUDIO_GENERIC,
		'png' => IMAGE,
		'xml' => TEXT,
		'txt' => TEXT,
		'json' => TEXT,
		'jsonc' => TEXT,
		'csv' => TEXT,
		'tsv' => TEXT,
		'hx' => TEXT,
		'hscript' => TEXT,
		'lua' => TEXT,
		'py' => TEXT,
		'frag' => TEXT,
		'vert' => TEXT,
		'ttf' => FONT,
		'otf' => FONT,
		'webm' => VIDEO,
		'mp4' => VIDEO,
		'swf' => VIDEO,
		'fla' => BINARY,
		'flp' => BINARY,
		'zip' => BINARY
	];

	public static var trackedMods:Array<ModMetadata> = [];

	private static var failedToReload:Bool = false;
	#end

	public static function reload():Void
	{
		#if FUTURE_POLYMOD
		trace('Reloading Polymod...');
		loadMods(getMods());
		if (failedToReload){
			trace('Failed to reload...');
			// return;
		}
		#else
		trace("Polymod reloading is not supported on your Platform!");
		#end
	}

	#if FUTURE_POLYMOD
	public static function loadMods(folders:Array<String>):Void
	{
		var loadedModlist:Array<ModMetadata> = Polymod.init({
			modRoot: MOD_DIR,
			dirs: folders,
			framework: OPENFL,
			apiVersion: API_VER,
			errorCallback: onError,
			parseRules: getParseRules(),
			extensionMap: extensions,
			ignoredFiles: Polymod.getDefaultIgnoreList()
		});

		if (loadedModlist != null && loadedModlist.length > 0 && folders != null && folders.length > 0)
			trace('Loading Successful, ${loadedModlist.length} / ${folders.length} new mods.');
		else {
			trace('Loading failed with mods');
			failedToReload = true;
			// return;
		}

		for (mod in loadedModlist)
			trace('Name: ${mod.title}, [${mod.id}]');
	}

	public static function getMods():Array<String>
	{
		trackedMods = [];

		var daList:Array<String> = [];

		trace('Searching for Mods...');

		for (i in Polymod.scan(MOD_DIR, '*.*.*', onError))
		{
			trackedMods.push(i);
			daList.push(i.id);
		}

		trace('Found ${daList.length} new mods.');

		return daList;
	}

	public static function getParseRules():ParseRules
	{
		var output:ParseRules = ParseRules.getDefault();
		output.addType("txt", TextFileFormat.LINES);
		output.addType("hx", TextFileFormat.PLAINTEXT);
		return output;
	}

	static function onError(error:PolymodError):Void
	{
		switch (error.severity)
		{
			case NOTICE:
				trace(error.message);
			case WARNING:
				trace(error.message);
			case ERROR:
				trace(error.message);
		}
	}
	#end
}