package meta.state;

#if desktop
import meta.data.dependency.Discord.DiscordClient;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

import flixel.addons.ui.FlxUIState;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.math.FlxRect;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import lime.app.Application;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import flixel.util.FlxSave;
import flixel.util.FlxAxes;
import flixel.animation.FlxAnimationController;
import animateatlas.AtlasFrameMaker;
import modcharting.ModchartFuncs;
import modcharting.NoteMovement;
import modcharting.PlayfieldRenderer;
import core.ScriptCore;

#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

#if VIDEOS_ALLOWED
#if (hxCodec >= "3.0.0") import hxcodec.flixel.FlxVideo as MP4Handler;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoHandler as MP4Handler;
#elseif (hxCodec == "2.6.0") import VideoHandler as MP4Handler;
#else import vlc.MP4Handler; #end
#end

#if WEBM_ALLOWED
import webm.WebmPlayer;
import meta.video.BackgroundVideo;
import meta.video.VideoSubState;
#end

#if FLASH_MOVIE
import meta.video.SwfVideo;
#end

#if HSCRIPT_ALLOWED
import hscript.*;
import horny.*;
#end

import meta.*;
import objects.*;
import meta.data.*;
import meta.video.*;
import meta.state.*;
import meta.substate.*;
import meta.data.scripts.*;
import meta.data.options.*;
import meta.state.editors.*;
import objects.shaders.*;
import objects.background.*;
import objects.userinterface.*;
import objects.userinterface.note.*;
import objects.userinterface.note.Note;
import objects.userinterface.DialogueBoxPsych;
import meta.state.ReplayState.ReplayPauseSubstate;
import meta.data.scripts.FunkinLua;
import meta.data.Achievements;
import meta.data.Conductor;
import meta.data.ModchartTween;
import meta.data.Song;
import meta.data.Section;
import meta.data.StageData;
import meta.data.WeekData;
import meta.MusicBeatState.ModchartSprite;
import meta.MusicBeatState.ModchartText;
import objects.Character;

import Type.ValueType;

using meta.CoolUtil;
using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 48.5;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var gameParameters:Map<String,Dynamic> = new Map<String,Dynamic>();
	public static var funk:FunkinUtil;

	public static var ratingStuff:Array<Dynamic> = [
		['F-', 0.2],
		['F', 0.5],
		['D', 0.6],
		['C', 0.7],
		['B', 0.8],
		['A-', 0.89],
		['A', 0.90],
		['A+', 0.93],
		['S-', 0.96],
		['S', 0.99],
		['S+', 0.997],
		['SS-', 0.998],
		['SS', 0.999],
		['SS+', 0.9995],
		['X-', 0.9997],
		['X', 0.9998],
		['X+', 0.999935],
		['P', 1.0]
	];

	public static var psychRatings:Array<Dynamic> = [
		['You Suck!', 0.2],
		['Shit', 0.4],
		['Bad', 0.5],
		['Bruh', 0.6],
		['Meh', 0.69],
		['Nice', 0.7],
		['Good', 0.8],
		['Great', 0.9],
		['Sick!', 1],
		['Perfect!!', 1]
	];

	public static var kadeRatings:Array<Dynamic> = [
		['D', 0.59],
		['C', 0.6],
		['B', 0.7],
		['A', 0.8],
		['A.', 0.85],
		['A:', 0.90],
		['AA', 0.93],
		['AA.', 0.965],
		['AA:', 0.99],
		['AAA', 0.997],
		['AAA.', 0.998],
		['AAA:', 0.999],
		['AAAA', 0.99955],
		['AAAA.', 0.9997],
		['AAAA:', 0.9998],
		['AAAAA', 0.999935]
	];

	//event variables
	private var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;

	var vocalsFinished:Bool = false;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;

	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	public var ratingsData:Array<Rating> = [];
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	var randomMode:Bool = false;
	var flip:Bool = false;
	var stairs:Bool = false;
	var waves:Bool = false;
	var oneK:Bool = false;
	var randomSpeedThing:Bool = false;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	
	public var camHUD:FlxCamera;
	// public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = null;
	var dialogueJson:DialogueFile = null;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleSmokes:FlxSpriteGroup;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var trainSound:FlxSound;
	var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var bgGhouls:BGSprite;

	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;

	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	var inReplay:Bool;

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;
	var achievementsArray:Array<FunkinLua> = [];
	var achievementWeeks:Array<String> = [];

	// Lua shit
	public static var instance:PlayState = null;
	#if LUA_ALLOWED
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	#end
	public var introSoundsSuffix:String = '';

	public var scriptArray:Array<FunkinSScript> = [];

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	private var controlArray:Array<String>;

	var precacheList:Map<String, String> = new Map<String, String>();
	
	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastCombo:FlxSprite;
	// stores the last combo score objects in an array
	public static var lastScore:Array<FlxSprite> = [];

	var nps:Int = 0;
	var npsArray:Array<Date> = [];
	var maxNPS:Int = 0;

	//the payload for beat-based buttplug support
	public var bpPayload:String = "";

	public var comboFunction:Void->Void = null;

	public static var inMini:Bool = false;

	public function setArrowSkinFromName(songName:String):Void
	{
		var noPlayerSkin = SONG.arrowSkin == null || SONG.arrowSkin.length < 1;
		var noOpponentSkin = SONG.opponentArrowSkin == null || SONG.opponentArrowSkin.length < 1;

		if(noPlayerSkin || noOpponentSkin){
			//W: I'll do this later but I'm adding this function for completion
			/*songName = songName.toLowerCase();
			switch (songName)
			{
				default: 
					if(noPlayerSkin) PlayState.SONG.arrowSkin = 'note_assets';
					if(noOpponentSkin) PlayState.SONG.opponentArrowSkin = "note_assets";
			}
			*/	
			//W: TO-DO, Add some hscript callback here lol.
		}
	}

	override public function create()
	{
		if (curStage != 'schoolEvil')
			Application.current.window.title = "Friday Night Funkin': Joalor64 Engine Rewritten - NOW PLAYING: " + '${SONG.song}';

		#if cpp
		cpp.vm.Gc.enable(true);
		#end
		openfl.system.System.gc();

		Paths.clearStoredMemory();

		// for lua
		instance = this;

		funk = new FunkinUtil(instance, true);

		if (!inReplay)
		{
			ReplayState.hits = [];
			ReplayState.miss = [];
			ReplayState.judgements = [];
			ReplayState.sustainHits = [];
		}

		removedVideo = false;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);

		controlArray = [
			'NOTE_LEFT',
			'NOTE_DOWN',
			'NOTE_UP',
			'NOTE_RIGHT'
		];

		keysArray = [];

		for (ass in controlArray)
			keysArray.push(ClientPrefs.copyKey(ClientPrefs.keyBinds.get(ass.toLowerCase())));

		comboFunction = () -> {
			// Rating FC
			switch (ClientPrefs.scoreTxtType)
			{
				case 'Default':
					ratingFC = "CB";
					if (songMisses < 1){
						if (shits > 0)
							ratingFC = "FC";
						else if (bads > 0)
							ratingFC = "GFC";
						else if (goods > 0)
							ratingFC = "MFC";
						else if (sicks > 0)
							ratingFC = "SFC";
					}
					else if (songMisses < 10){
						ratingFC = "SDCB";
					}
					else if (cpuControlled){
						ratingFC = "Cheater!";
					}
				
				case 'Psych':
					ratingFC = "";
					if (sicks > 0) ratingFC = "SFC";
					if (goods > 0) ratingFC = "GFC";
					if (bads > 0 || shits > 0) ratingFC = "FC";
					if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
					else if (songMisses >= 10) ratingFC = "Clear";

				case 'Kade':
					ratingFC = "N/A";
					if (cpuControlled)
						ratingFC = "Botplay";

					if (songMisses == 0 && sicks >= 0 && goods == 0 && bads == 0 && shits == 0)
						ratingFC = "(MFC) ";
					else if (songMisses == 0 && goods >= 0 && bads == 0 && shits == 0)
						ratingFC = "(GFC) ";
					else if (songMisses == 0)
						ratingFC = "(FC) ";
					else if (songMisses <= 10)
						ratingFC = "(SDCB) ";
					else
						ratingFC = "(Clear) ";
			}		
		}

		//Ratings
		var rating:Rating = new Rating('sick');
		rating.ratingMod = 1;
		rating.score = 350;
		rating.noteSplash = true;
		ratingsData.push(rating);

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.75;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.5;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
			keysPressed.push(false);

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		randomMode = ClientPrefs.getGameplaySetting('randommode', false);
		flip = ClientPrefs.getGameplaySetting('flip', false);
		stairs = ClientPrefs.getGameplaySetting('stairmode', false);
		waves = ClientPrefs.getGameplaySetting('wavemode', false);
		oneK = ClientPrefs.getGameplaySetting('onekey', false);
		randomSpeedThing = ClientPrefs.getGameplaySetting('randomspeed', false);

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);
		songName = songName.toLowerCase();

		setArrowSkinFromName(songName);

		curStage = SONG.stage;
		if(SONG.stage == null || SONG.stage.length < 1) {
			switch (songName)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				case 'ugh' | 'guns' | 'stress':
					curStage = 'tank';
				default:
					curStage = 'stage';
			}
		}
		SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stages/stage/stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stages/stage/stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stages/stage/stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stages/stage/stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stages/stage/stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
				dadbattleSmokes = new FlxSpriteGroup(); //troll'd

			case 'spooky': //Week 2
				if(!ClientPrefs.lowQuality) {
					halloweenBG = new BGSprite('stages/spooky/halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				} else {
					halloweenBG = new BGSprite('stages/spooky/halloween_bg_low', -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				//PRECACHE SOUNDS
				precacheList.set('thunder_1', 'sound');
				precacheList.set('thunder_2', 'sound');

			case 'philly': //Week 3
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('stages/philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}

				var city:BGSprite = new BGSprite('stages/philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
				phillyWindow = new BGSprite('stages/philly/window', city.x, city.y, 0.3, 0.3);
				phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
				phillyWindow.updateHitbox();
				add(phillyWindow);
				phillyWindow.alpha = 0;

				if(!ClientPrefs.lowQuality) {
					var streetBehind:BGSprite = new BGSprite('stages/philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('stages/philly/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				phillyStreet = new BGSprite('stages/philly/street', -40, 50);
				add(phillyStreet);

			case 'limo': //Week 4
				var skyBG:BGSprite = new BGSprite('stages/limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if(!ClientPrefs.lowQuality) {
					limoMetalPole = new BGSprite('stages/limo/gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('stages/limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('stages/limo/gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('stages/limo/gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 170, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('stages/limo/gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					//PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('stages/limo/gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					//PRECACHE SOUND
					precacheList.set('dancerdeath', 'sound');
				}

				limo = new BGSprite('stages/limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite('stages/limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall': //Week 5 - Cocoa, Eggnog
				var bg:BGSprite = new BGSprite('stages/mall/christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if(!ClientPrefs.lowQuality) {
					upperBoppers = new BGSprite('stages/mall/christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('stages/mall/christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('stages/mall/christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('stages/mall/christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('stages/mall/christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('stages/mall/christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				precacheList.set('Lights_Shut_off', 'sound');

			case 'mallEvil': //Week 5 - Winter Horrorland
				var bg:BGSprite = new BGSprite('stages/mall/christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('stages/mall/christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('stages/mall/christmas/evilSnow', -200, 700);
				add(evilSnow);

			case 'school': //Week 6 - Senpai, Roses
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				var bgSky:BGSprite = new BGSprite('stages/school/weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('stages/school/weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('stages/school/weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if(!ClientPrefs.lowQuality) {
					var fgTrees:BGSprite = new BGSprite('stages/school/weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('stages/school/weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if(!ClientPrefs.lowQuality) {
					var treeLeaves:BGSprite = new BGSprite('stages/school/weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if(!ClientPrefs.lowQuality) {
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

			case 'schoolEvil': //Week 6 - Thorns
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				var posX = 400;
				var posY = 200;
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('stages/school/weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('stages/school/weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				} else {
					var bg:BGSprite = new BGSprite('stages/school/weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}

			case 'tank': //Week 7 - Ugh, Guns, Stress
				var sky:BGSprite = new BGSprite('stages/tank/tankSky', -400, -400, 0, 0);
				add(sky);

				if(!ClientPrefs.lowQuality)
				{
					var clouds:BGSprite = new BGSprite('stages/tank/tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);
					add(clouds);

					var mountains:BGSprite = new BGSprite('stages/tank/tankMountains', -300, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();
					add(mountains);

					var buildings:BGSprite = new BGSprite('stages/tank/tankBuildings', -200, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();
					add(buildings);
				}

				var ruins:BGSprite = new BGSprite('stages/tank/tankRuins',-200,0,.35,.35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();
				add(ruins);

				if(!ClientPrefs.lowQuality)
				{
					var smokeLeft:BGSprite = new BGSprite('stages/tank/smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);
					var smokeRight:BGSprite = new BGSprite('stages/tank/smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);

					tankWatchtower = new BGSprite('stages/tank/tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tankWatchtower);
				}

				tankGround = new BGSprite('stages/tank/tankRolling', 300, 300, 0.5, 0.5,['BG tank w lighting'], true);
				add(tankGround);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				var ground:BGSprite = new BGSprite('stages/tank/tankGround', -420, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				add(ground);
				moveTank();

				foregroundSprites = new FlxTypedGroup<BGSprite>();
				foregroundSprites.add(new BGSprite('stages/tank/tank0', -500, 650, 1.7, 1.5, ['fg']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('stages/tank/tank1', -300, 750, 2, 0.2, ['fg']));
				foregroundSprites.add(new BGSprite('stages/tank/tank2', 450, 940, 1.5, 1.5, ['foreground']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('stages/tank/tank4', 1300, 900, 1.5, 1.5, ['fg']));
				foregroundSprites.add(new BGSprite('stages/tank/tank5', 1620, 700, 1.5, 1.5, ['fg']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('stages/tank/tank3', 1300, 1200, 3.5, 2.5, ['fg']));
		}

		switch(Paths.formatToSongPath(SONG.song))
		{
			case 'stress':
				GameOverSubstate.characterName = 'bf-holding-gf-dead';
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup); //Needed for blammed lights

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		add(dadGroup);
		add(boyfriendGroup);

		switch(curStage)
		{
			case 'spooky':
				add(halloweenWhite);
			case 'tank':
				add(foregroundSprites);
			default:
				callStageFunctions("foregroundAdd", []);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		function addAbilityToUnlockAchievements(funkinLua:FunkinLua)
		{
			var lua = funkinLua.lua;
			if (lua != null){
				Lua_helper.add_callback(lua, "giveAchievement", function(name:String){
					if (luaArray.contains(funkinLua))
						throw 'Illegal attempt to unlock ' + name;
					@:privateAccess
					if (Achievements.isAchievementUnlocked(name))
						return "Achievement " + name + " is already unlocked!";
					if (!Achievements.exists(name))
						return "Achievement " + name + " does not exist."; 
					if(instance != null) { 
						Achievements.unlockAchievement(name);
						instance.startAchievement(name);
						ClientPrefs.saveSettings();
						return "Unlocked achievement " + name + "!";
					}
					else return "Instance is null.";
				});
			}
		}

		//CUSTOM ACHIVEMENTS
		#if (MODS_ALLOWED && FUTURE_POLYMOD && LUA_ALLOWED && ACHIEVEMENTS_ALLOWED)
		var luaFiles:Array<String> = Achievements.getModAchievements().copy();
		if(luaFiles.length > 0)
		{
			for(luaFile in luaFiles)
			{
				var meta:Achievements.AchievementMeta = try Json.parse(File.getContent(luaFile.substring(0, luaFile.length - 4) + '.json')) catch(e) throw e;
				if (meta != null)
				{
					if ((meta.global == null || meta.global.length < 1) && meta.song != null && meta.song.length > 0 && SONG.song.toLowerCase().replace(' ', '-') != meta.song.toLowerCase().replace(' ', '-'))
						continue;

					var lua = new FunkinLua(luaFile);
					addAbilityToUnlockAchievements(lua);
					achievementsArray.push(lua);
				}
			}
		}

		var achievementMetas = Achievements.getModAchievementMetas().copy();
		for (i in achievementMetas) { 
			if (i.global == null || i.global.length < 1)
			{
				if(i.song != null)
				{
					if(i.song.length > 0 && SONG.song.toLowerCase().replace(' ', '-') != i.song.toLowerCase().replace(' ', '-'))
						continue;
				}
				if(i.lua_code != null) {
					var lua = new FunkinLua(null, i.lua_code);
					addAbilityToUnlockAchievements(lua);
					achievementsArray.push(lua);
				}
				if(i.week_nomiss != null) {
					achievementWeeks.push(i.week_nomiss + '_nomiss');
				}
			}
		}
		#end

		// "GLOBAL" SCRIPTS
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getPreloadPath(), 'scripts/');
		for (folder in foldersToCheck)
		{
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					luaArray.push(new FunkinLua(folder + file));
				#elseif HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hscript'))
					addHscript(folder + file);
				#elseif SCRIPT_EXTENSION
				if(file.toLowerCase().endsWith('.hx'))
					scriptArray.push(new FunkinSScript(folder + file));
				#end
			}
		}

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && FUTURE_POLYMOD)
		var doPush:Bool = false;
		#if LUA_ALLOWED
		var luaFile:String = 'stages/' + curStage + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush)
			luaArray.push(new FunkinLua(luaFile));
		#elseif HSCRIPT_ALLOWED
		var hscriptFile:String = 'stages/' + curStage + '.hscript';
		if(FileSystem.exists(Paths.modFolders(hscriptFile))) {
			hscriptFile = Paths.modFolders(hscriptFile);
			doPush = true;
		} else {
			hscriptFile = Paths.getPreloadPath(hscriptFile);
			if(FileSystem.exists(hscriptFile)) {
				doPush = true;
			}
		}

		if(doPush)
			addHscript(hscriptFile);
		#elseif SCRIPT_EXTENSION
		var scriptFile:String = 'stages/' + curStage + '.hx';
		if(FileSystem.exists(Paths.modFolders(scriptFile))) {
			scriptFile = Paths.modFolders(scriptFile);
			doPush = true;
		} else {
			scriptFile = Paths.getPreloadPath(scriptFile);
			if(FileSystem.exists(scriptFile)) {
				doPush = true;
			}
		}

		if(doPush)
			scriptArray.push(new FunkinSScript(scriptFile));
		#end
		#end

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				case 'tank':
					gfVersion = 'gf-tankmen';
				default:
					gfVersion = 'gf';
			}

			switch(Paths.formatToSongPath(SONG.song))
			{
				case 'stress':
					gfVersion = 'pico-speaker';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);

			if(gfVersion == 'pico-speaker')
			{
				if(!ClientPrefs.lowQuality)
				{
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetShit(20, 600, true);
					firstTank.strumTime = 10;
					tankmanRun.add(firstTank);

					for (i in 0...TankmenBG.animationNotes.length)
					{
						if(FlxG.random.bool(16)) {
							var tankBih = tankmanRun.recycle(TankmenBG);
							tankBih.strumTime = TankmenBG.animationNotes[i][0];
							tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
							tankmanRun.add(tankBih);
						}
					}
				}
			}
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		switch(curStage)
		{
			case 'limo':
				resetFastCar();
				addBehindGF(fastCar);

			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice
				addBehindDad(evilTrail);
		}

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file))
			dialogueJson = DialogueBoxPsych.parseDialogue(file);

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file))
			dialogue = CoolUtil.coolTextFile(file);

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000 / Conductor.songPosition;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
			timeTxt.text = SONG.song;

		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong();

		playfieldRenderer = new PlayfieldRenderer(strumLineNotes, notes, this);
		playfieldRenderer.cameras = [camHUD];
		add(playfieldRenderer);
		add(grpNoteSplashes);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null && prevCamFollowPos != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;

			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;			
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		moveCameraSection();

		healthBarBG = new AttachedSprite((ClientPrefs.longBar) ? 'healthBarLong' : 'healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		iconP1.canBounce = true;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		iconP2.canBounce = true;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if(ClientPrefs.downScroll)
			botplayTxt.y = timeBarBG.y - 78;

		var versionTxt:FlxText = new FlxText(4, FlxG.height - 24, 0, '${SONG.song} ${CoolUtil.difficultyString()} - Joalor64 Engine Rewrite v${MainMenuState.joalor64EngineVersion}', 12);
		versionTxt.scrollFactor.set();
		versionTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionTxt);

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];
		versionTxt.cameras = [camHUD];

		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypes)
		{
			#if (MODS_ALLOWED && FUTURE_POLYMOD)
			var luaToLoad:String = Paths.modFolders('notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('notetypes/' + notetype + '.lua');
			if(OpenFlAssets.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			#end
		}
		for (event in eventsPushed)
		{
			#if (MODS_ALLOWED && FUTURE_POLYMOD)
			var luaToLoad:String = Paths.modFolders('events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('events/' + event + '.lua');
			if(OpenFlAssets.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			#end
		}
		#end
		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
		{
			#if (MODS_ALLOWED && FUTURE_POLYMOD)
			var hscriptToLoad:String = Paths.modFolders('notetypes/' + notetype + '.hscript');
			if(FileSystem.exists(hscriptToLoad))
			{
				addHscript(hscriptToLoad);
			}
			else
			{
				hscriptToLoad = Paths.getPreloadPath('notetypes/' + notetype + '.hscript');
				if(FileSystem.exists(hscriptToLoad))
				{
					addHscript(hscriptToLoad);
				}
			}
			#elseif sys
			var hscriptToLoad:String = Paths.getPreloadPath('notetypes/' + notetype + '.hscript');
			if(OpenFlAssets.exists(hscriptToLoad))
			{
				addHscript(hscriptToLoad);
			}
			#end
		}
		for (event in eventsPushed)
		{
			#if (MODS_ALLOWED && FUTURE_POLYMOD)
			var hscriptToLoad:String = Paths.modFolders('events/' + event + '.hscript');
			if(FileSystem.exists(hscriptToLoad))
			{
				addHscript(hscriptToLoad);
			}
			else
			{
				hscriptToLoad = Paths.getPreloadPath('events/' + event + '.hscript');
				if(FileSystem.exists(hscriptToLoad))
				{
					addHscript(hscriptToLoad);
				}
			}
			#elseif sys
			var hscriptToLoad:String = Paths.getPreloadPath('events/' + event + '.hscript');
			if(OpenFlAssets.exists(hscriptToLoad))
			{
				addHscript(hscriptToLoad);
			}
			#end
		}
		#end
		#if SCRIPT_EXTENSION
		for (notetype in noteTypes)
		{
			#if (MODS_ALLOWED && FUTURE_POLYMOD)
			var hxToLoad:String = Paths.modFolders('notetypes/' + notetype + '.hx');
			if(FileSystem.exists(hxToLoad))
			{
				scriptArray.push(new FunkinSScript(hxToLoad));
			}
			else
			{
				hxToLoad = Paths.getPreloadPath('notetypes/' + notetype + '.hx');
				if(FileSystem.exists(hxToLoad))
				{
					scriptArray.push(new FunkinSScript(hxToLoad));
				}
			}
			#elseif sys
			var hxToLoad:String = Paths.getPreloadPath('notetypes/' + notetype + '.hx');
			if(OpenFlAssets.exists(hxToLoad))
			{
				scriptArray.push(new FunkinSScript(hxToLoad));
			}
			#end
		}
		for (event in eventsPushed)
		{
			#if (MODS_ALLOWED && FUTURE_POLYMOD)
			var hxToLoad:String = Paths.modFolders('events/' + event + '.hx');
			if(FileSystem.exists(hxToLoad))
			{
				scriptArray.push(new FunkinSScript(hxToLoad));
			}
			else
			{
				hxToLoad = Paths.getPreloadPath('events/' + event + '.hx');
				if(FileSystem.exists(hxToLoad))
				{
					scriptArray.push(new FunkinSScript(hxToLoad));
				}
			}
			#elseif sys
			var hxToLoad:String = Paths.getPreloadPath('events/' + event + '.hx');
			if(OpenFlAssets.exists(hxToLoad))
			{
				scriptArray.push(new FunkinSScript(hxToLoad));
			}
			#end
		}
		#end
		noteTypes = null;
		eventsPushed = null;

		// SONG SPECIFIC SCRIPTS
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getPreloadPath(), 'data/' + songName + '/');
		for (folder in foldersToCheck)
		{
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					luaArray.push(new FunkinLua(folder + file));
				#elseif HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hscript'))
					addHscript(folder + file);
				#elseif SCRIPT_EXTENSION
				if(file.toLowerCase().endsWith('.hx'))
					scriptArray.push(new FunkinSScript(folder + file));
				#end
			}
		}

		if (isStoryMode && !seenCutscene)
		{
			switch (SONG.song.toLowerCase())
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					if(gf != null) gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if(SONG.song.toLowerCase() == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);

				case 'ugh' | 'guns' | 'stress':
					tankIntro();

				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
			startCountdown();

		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) 
			precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null)
			precacheList.set(PauseSubState.songName, 'music');
		else if(ClientPrefs.pauseMusic != 'None')
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');

		precacheList.set('alphabet', 'image');
	
		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		ModchartFuncs.loadLuaFunctions();

		#if HSCRIPT_ALLOWED
		postSetHscript();
		#end
		callOnLuas('onCreatePost', []);

		// no point in these if antialiasing is off
		if (boyfriend.antialiasing == true)
			boyfriend.antialiasing = ClientPrefs.globalAntialiasing;
		if (dad.antialiasing == true)
			dad.antialiasing = ClientPrefs.globalAntialiasing;
		if (gf.antialiasing == true)
			gf.antialiasing = ClientPrefs.globalAntialiasing;

		super.create();

		cacheCountdown();
		cachePopUpScore();
		for (key => type in precacheList)
		{
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
				case 'video':
					Paths.video(key);
			}
		}
		Paths.clearUnusedMemory();
		
		CustomFadeTransition.nextCamera = camOther;
	}

	#if (!flash && sys)
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && FUTURE_POLYMOD && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.shaders) return false;

		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for(mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		
		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		return false;
	}
	#end

	inline function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	inline function set_playbackRate(value:Float):Float
	{
		if(generatedMusic)
		{
			if(vocals != null) vocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		trace('Anim speed: ' + FlxAnimationController.globalSpeed);
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * value;
		setOnLuas('playbackRate', playbackRate);
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor = FlxColor.WHITE) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));

		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}
	#if HSCRIPT_ALLOWED
	var hscriptMap:Map<String, FunkinHscript> = new Map();
	public function addHscript(path:String) {
		var parser = new ParserEx();
		try {
			var program = parser.parseString(Paths.getContent(path));
			var interp = new FunkinHscript(path);

			//FUNCTIONS
			interp.variables.set('add', PlayState.instance.add);
			interp.variables.set('insert', PlayState.instance.insert);
			interp.variables.set('remove', remove);
			interp.variables.set('addBehindChars', function(obj:FlxBasic) {
				var index = members.indexOf(gfGroup);
				if (members.indexOf(dadGroup) < index) {
					index = members.indexOf(dadGroup);
				}
				if (members.indexOf(boyfriendGroup) < index) {
					index = members.indexOf(boyfriendGroup);
				}
				insert(index, obj);
			});
			interp.variables.set('addOverChars', function(obj:FlxBasic) {
				var index = members.indexOf(boyfriendGroup);
				if (members.indexOf(dadGroup) > index) {
					index = members.indexOf(dadGroup);
				}
				if (members.indexOf(gfGroup) > index) {
					index = members.indexOf(gfGroup);
				}
				insert(index + 1, obj);
			});
			interp.variables.set('getObjectOrder', function(obj:Dynamic) {
				if ((obj is String)) {
					var basic:FlxBasic = Reflect.getProperty(this, obj);
					if (basic != null) {
						return members.indexOf(basic);
					}
					return -1;
				} else {
					return members.indexOf(obj);
				}
			});
			interp.variables.set('setObjectOrder', function(obj:Dynamic, pos:Int = 0) {
				if ((obj is String)) {
					var basic:FlxBasic = Reflect.getProperty(this, obj);
					if (basic != null) {
						if (members.indexOf(basic) > -1) {
							remove(basic);
						}
						insert(pos, basic);
					}
				} else {
					if (members.indexOf(obj) > -1) {
						remove(obj);
					}
					insert(pos, obj);
				}
			});
			interp.variables.set('openSubState', openSubState);
			interp.variables.set('closeSubState', closeSubState);
			interp.variables.set('getProperty', function(variable:String) {
				return Reflect.getProperty(this, variable);
			});
			interp.variables.set('setProperty', function(variable:String, value:Dynamic) {
				Reflect.setProperty(this, variable, value);
			});
			interp.variables.set('getPropertyFromClass', function(classVar:String, variable:String) {
				return Reflect.getProperty(Type.resolveClass(classVar), variable);
			});
			interp.variables.set('setPropertyFromClass', function(classVar:String, variable:String, value:Dynamic) {
				Reflect.setProperty(Type.resolveClass(classVar), variable, value);
			});
			interp.variables.set('addScript', function(name:String, ?ignoreAlreadyRunning:Bool = false) {
				var cervix = '$name.hscript';
				var doPush = false;
				#if (MODS_ALLOWED && FUTURE_POLYMOD)
				if (FileSystem.exists(Paths.modFolders(cervix))) {
					cervix = Paths.modFolders(cervix);
					doPush = true;
				} else {
				#end
					cervix = Paths.getPreloadPath(cervix);
					if (OpenFlAssets.exists(cervix)) {
						doPush = true;
					}
				#if (MODS_ALLOWED && FUTURE_POLYMOD)	
				}
				#end

				if (doPush)
				{
					if (!ignoreAlreadyRunning && hscriptMap.exists(cervix))
					{
						addTextToDebug('The script "$cervix" is already running!');
						return;
					}
					addHscript(cervix);
					return;
				}
				addTextToDebug("Script doesn't exist!");
			});
			interp.variables.set('removeScript', function(name:String) {
				var cervix = '$name.hscript';
				var doPush = false;
				#if (MODS_ALLOWED && FUTURE_POLYMOD)
				if (FileSystem.exists(Paths.modFolders(cervix))) {
					cervix = Paths.modFolders(cervix);
					doPush = true;
				} else {
				#end
					cervix = Paths.getPreloadPath(cervix);
					if (OpenFlAssets.exists(cervix)) {
						doPush = true;
					}
				#if (MODS_ALLOWED && FUTURE_POLYMOD)	
				}
				#end

				if (doPush)
				{
					if (hscriptMap.exists(cervix))
					{
						var hscript = hscriptMap.get(cervix);
						hscriptMap.remove(cervix);
						hscript = null;
						return;
					}
					return;
				}
				addTextToDebug("Script doesn't exist!");
			});
			interp.variables.set('debugPrint', function(text:Dynamic) {
				addTextToDebug('$text');
				trace(text);
			});

			//EVENTS
			var funcs = [
				'onStepHit',
				'onBeatHit',
				'onStartCountdown',
				'onSongStart',
				'onEndSong',
				'onSkipCutscene',
				'onBPMChange',
				'onOpenChartEditor',
				'onOpenCharacterEditor',
				'onPause',
				'onResume',
				'onGameOver',
				'onRecalculateRating'
			];
			for (i in funcs)
				interp.variables.set(i, function() {});
			interp.variables.set('onCountdownTick', function(counter) {});
			interp.variables.set('onNextDialogue', function(line) {});
			interp.variables.set('onSkipDialogue', function(line) {});
			interp.variables.set('goodNoteHit', function(id, direction, noteType, isSustainNote) {});
			interp.variables.set('opponentNoteHit', function(id, direction, noteType, isSustainNote) {});
			interp.variables.set('noteMissPress', function(direction) {});
			interp.variables.set('noteMiss', function(id, direction, noteType, isSustainNote) {});
			interp.variables.set('onMoveCamera', function(focus) {});
			interp.variables.set('onEvent', function(name, value1, value2) {});
			interp.variables.set('eventPushed', function(name, strumTime, value1, value2) {});
			interp.variables.set('eventEarlyTrigger', function(name) {});
			interp.variables.set('onTweenCompleted', function(tag) {});
			interp.variables.set('onTimerCompleted', function(tag, loops, loopsLeft) {});

			interp.execute(program);
			hscriptMap.set(path, interp);
			callHscript(path, 'onCreate', []);
		} catch (e) {
			trace(e);
			addTextToDebug('$e');
			addTextToDebug('Could not load script $path');
		}
	}

	function callHscript(name:String, func:String, args:Array<Dynamic>) {
		if (!hscriptMap.exists(name) || !hscriptMap.get(name).variables.exists(func)) {
			return FunkinLua.Function_Continue;
		}
		var method = hscriptMap.get(name).variables.get(func);
		var ret:Dynamic = Reflect.callMethod(null, method, args); // allows for infinite args

		if (ret != null && ret != FunkinLua.Function_Continue) {
			return ret;
		}
		return FunkinLua.Function_Continue;
	}

	#if HSCRIPT_ALLOWED
	// scriptcore crap
	inline function executeScript(name:String, ?execCreate:Bool = false){
		ScriptCore.instance.execute(name, execCreate);
	}

	inline function setVar(name:String, val:Dynamic){
		ScriptCore.instance.setVariable(name, val);
	}

	inline function getVar(name:String){
		return (ScriptCore.instance.existsVariable(name)) ? ScriptCore.instance.getVariable(name) : null;
	}

	inline function existsVar(name:String){
		return ScriptCore.instance.existsVariable(name);
	}

	inline function executeFunc(name:String){
		return ScriptCore.instance.executeFunc(name);
	}
	#end

	function postSetHscript() {
		setOnHscripts('boyfriend', boyfriend);
		setOnHscripts('dad', dad);
		setOnHscripts('gf', gf);
		setOnHscripts('strumLineNotes', strumLineNotes);
		setOnHscripts('playerStrums', playerStrums);
		setOnHscripts('opponentStrums', opponentStrums);
		setOnHscripts('iconP1', iconP1);
		setOnHscripts('iconP2', iconP2);
		setOnHscripts('grpNoteSplashes', grpNoteSplashes);
		setOnHscripts('scoreTxt', scoreTxt);
		setOnHscripts('healthBar', healthBar);
		setOnHscripts('botplayTxt', botplayTxt);
		setOnHscripts('timeBar', timeBar);
		setOnHscripts('timeTxt', timeTxt);
		setOnHscripts('boyfriendGroup', boyfriendGroup);
		setOnHscripts('dadGroup', dadGroup);
		setOnHscripts('gfGroup', gfGroup);
		setOnHscripts('camGame', camGame);
		setOnHscripts('camHUD', camHUD);
		setOnHscripts('camOther', camOther);
		setOnHscripts('camFollow', camFollow);
		setOnHscripts('camFollowPos', camFollowPos);
		setOnHscripts('strumLine', strumLine);
	}
	#end

	function setOnHscripts(variable:String, arg:Dynamic) {
		#if HSCRIPT_ALLOWED
		for (i in hscriptMap.keys()) {
			hscriptMap.get(i).variables.set(variable, arg);
		}
		#end
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		#if (MODS_ALLOWED && FUTURE_POLYMOD)
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) {
			doPush = true;
		}
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end

		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var hscriptFile:String = 'characters/$name.hscript';
		#if (MODS_ALLOWED && FUTURE_POLYMOD)
		if (FileSystem.exists(Paths.modFolders(hscriptFile))) {
			hscriptFile = Paths.modFolders(hscriptFile);
			doPush = true;
		} else {
		#end
			hscriptFile = Paths.getPreloadPath(hscriptFile);
			if (OpenFlAssets.exists(hscriptFile)) {
				doPush = true;
			}
		#if (MODS_ALLOWED && FUTURE_POLYMOD)
		}
		#end
		
		if (doPush && !hscriptMap.exists(hscriptFile))
		{
			addHscript(hscriptFile);
		}
		#end

		#if SCRIPT_EXTENSION
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		#if (MODS_ALLOWED && FUTURE_POLYMOD)
		if(FileSystem.exists(Paths.modFolders(scriptFile))) {
			scriptFile = Paths.modFolders(scriptFile);
			doPush = true;
		} else {
			scriptFile = Paths.getPreloadPath(scriptFile);
			if(FileSystem.exists(scriptFile)) {
				doPush = true;
			}
		}
		#else
		scriptFile = Paths.getPreloadPath(scriptFile);
		if(Assets.exists(scriptFile)) {
			doPush = true;
		}
		#end

		if(doPush)
		{
			for (script in scriptArray)
			{
				if(script.scriptFile == scriptFile) return;
			}
			scriptArray.push(new FunkinSScript(scriptFile));
		}
		#end
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	override public function startVideo(name:String)
	{
		#if (VIDEOS_ALLOWED || WEBM_ALLOWED)
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}
		#if WEBM_ALLOWED
		openSubState(new VideoSubState(name, null, () -> startAndEnd()));
		return;
		#else
		var video:MP4Handler = new MP4Handler();
		#if (hxCodec >= "3.0.0")
		// Recent versions
		video.play(filepath);
		video.onEndReached.add(function()
		{
			video.dispose();
			startAndEnd();
			return;
		}, true);
		#else
		// Older versions
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			startAndEnd();
			return;
		}
		#end
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}
	public function startMovie(name:String, sound:String) // I fixed it joalor
	{
		#if FLASH_MOVIE
		inCutscene = true;

		var filepath:String = Paths.flashMovie(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find swf file: ' + name);
			startAndEnd();
			return;
		}
		var video:SwfVideo = new SwfVideo(filepath, sound, function() {
			startAndEnd();
			return;
		});
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	inline function startAndEnd(){
		(endingSong) ? endSong() : startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong)
				endSong();
			else 
				startCountdown();
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('stages/school/weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
						add(dialogueBox);
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function tankIntro()
	{
		var cutsceneHandler:CutsceneHandler = new CutsceneHandler();

		var songName:String = Paths.formatToSongPath(SONG.song);
		dadGroup.alpha = 0.00001;
		camHUD.visible = false;

		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
		tankman.antialiasing = ClientPrefs.globalAntialiasing;
		addBehindDad(tankman);
		cutsceneHandler.push(tankman);

		var tankman2:FlxSprite = new FlxSprite(16, 312);
		tankman2.antialiasing = ClientPrefs.globalAntialiasing;
		tankman2.alpha = 0.000001;
		cutsceneHandler.push(tankman2);
		var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
		gfDance.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfDance);
		var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
		gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfCutscene);
		var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
		picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(picoCutscene);
		var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(boyfriendCutscene);

		cutsceneHandler.finishCallback = function()
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			moveCamera(true);
			startCountdown();

			dadGroup.alpha = 1;
			camHUD.visible = true;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
		};

		camFollow.set(dad.x + 280, dad.y + 170);
		switch(songName)
		{
			case 'ugh':
				cutsceneHandler.endTime = 12;
				cutsceneHandler.music = 'DISTORTO';
				precacheList.set('wellWellWell', 'sound');
				precacheList.set('killYou', 'sound');
				precacheList.set('bfBeep', 'sound');

				var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell'));
				FlxG.sound.list.add(wellWellWell);

				tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankman.animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;

				// Well well well, what do we got here?
				// EDUARDO???
				cutsceneHandler.timer(0.1, function()
				{
					wellWellWell.play(true);
				});

				// Move camera to BF
				cutsceneHandler.timer(3, function()
				{
					camFollow.x += 750;
					camFollow.y += 100;
				});

				// Beep!
				cutsceneHandler.timer(4.5, function()
				{
					boyfriend.playAnim('singUP', true);
					boyfriend.specialAnim = true;
					FlxG.sound.play(Paths.sound('bfBeep'));
				});

				// Move camera to Tankman
				cutsceneHandler.timer(6, function()
				{
					camFollow.x -= 750;
					camFollow.y -= 100;

					// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
					tankman.animation.play('killYou', true);
					FlxG.sound.play(Paths.sound('killYou'));
				});

			case 'guns':
				cutsceneHandler.endTime = 11.5;
				cutsceneHandler.music = 'DISTORTO';
				tankman.x += 40;
				tankman.y += 10;
				precacheList.set('tankSong2', 'sound');

				var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
				FlxG.sound.list.add(tightBars);

				tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
				tankman.animation.play('tightBars', true);
				boyfriend.animation.curAnim.finish();

				cutsceneHandler.onStart = function()
				{
					tightBars.play(true);
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
				};

				cutsceneHandler.timer(4, function()
				{
					gf.playAnim('sad', true);
					gf.animation.finishCallback = function(name:String)
					{
						gf.playAnim('sad', true);
					};
				});

			case 'stress':
				cutsceneHandler.endTime = 35.5;
				tankman.x -= 54;
				tankman.y -= 14;
				gfGroup.alpha = 0.00001;
				boyfriendGroup.alpha = 0.00001;
				camFollow.set(dad.x + 400, dad.y + 170);
				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.y += 100;
				});
				precacheList.set('stressCutscene', 'sound');

				tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
				addBehindDad(tankman2);

				if (!ClientPrefs.lowQuality)
				{
					gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
					gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
					gfDance.animation.play('dance', true);
					addBehindGF(gfDance);
				}

				gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				gfCutscene.animation.play('dieBitch', true);
				gfCutscene.animation.pause();
				addBehindGF(gfCutscene);
				if (!ClientPrefs.lowQuality)
				{
					gfCutscene.alpha = 0.00001;
				}

				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				addBehindGF(picoCutscene);
				picoCutscene.alpha = 0.00001;

				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('idle', true);
				boyfriendCutscene.animation.curAnim.finish();
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);

				tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
				tankman.animation.play('godEffingDamnIt', true);

				var calledTimes:Int = 0;
				var zoomBack:Void->Void = function()
				{
					var camPosX:Float = 630;
					var camPosY:Float = 425;
					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);
					FlxG.camera.zoom = 0.8;
					cameraSpeed = 1;

					calledTimes++;
					if (calledTimes > 1)
					{
						foregroundSprites.forEach(function(spr:BGSprite)
						{
							spr.y -= 100;
						});
					}
				}

				cutsceneHandler.onStart = function()
				{
					cutsceneSnd.play(true);
				};

				cutsceneHandler.timer(15.2, function()
				{
					FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);
					gfCutscene.animation.finishCallback = function(name:String)
					{
						if(name == 'dieBitch') //Next part
						{
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						}
						else
						{
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.animation.play('anim', true);

							boyfriendGroup.alpha = 1;
							boyfriendCutscene.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String)
							{
								if(name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
								}
							};

							picoCutscene.animation.finishCallback = function(name:String)
							{
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};
							gfCutscene.animation.finishCallback = null;
						}
					};
				});

				cutsceneHandler.timer(17.5, function()
				{
					zoomBack();
				});

				cutsceneHandler.timer(19.5, function()
				{
					tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankman2.animation.play('lookWhoItIs', true);
					tankman2.alpha = 1;
					tankman.visible = false;
				});

				cutsceneHandler.timer(20, function()
				{
					camFollow.set(dad.x + 500, dad.y + 170);
				});

				cutsceneHandler.timer(31.2, function()
				{
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = function(name:String)
					{
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
						}
					};

					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
				});

				cutsceneHandler.timer(32.2, function()
				{
					zoomBack();
				});
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownThree:FlxSprite;
	public var countdownTwo:FlxSprite;
	public var countdownOne:FlxSprite;
	public var countdownGo:FlxSprite;
	
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', [
			'three',
			'two', 
			'one', 
			'go'
		]);
		introAssets.set('pixel', [
			'pixelUI/three-pixel',
			'pixelUI/two-pixel', 
			'pixelUI/one-pixel', 
			'pixelUI/date-pixel'
		]);

		var introAlts:Array<String> = introAssets.get('default');
		if (isPixelStage) introAlts = introAssets.get('pixel');
		
		for (asset in introAlts)
			Paths.image(asset);
		
		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', [], false);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			NoteMovement.getDefaultStrumPos(this);
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
				setOnHscripts('playerStrums', playerStrums);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				setOnHscripts('opponentStrums', opponentStrums);
				setOnHscripts('opponentStrums', opponentStrums);
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
					gf.dance();
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
					boyfriend.dance();
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
					dad.dance();

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', [
					'three',
					'two', 
					'one', 
					'go'
				]);
				introAssets.set('pixel', [
					'pixelUI/three-pixel',
					'pixelUI/two-pixel', 
					'pixelUI/one-pixel', 
					'pixelUI/date-pixel'
				]);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if(curStage == 'mall') {
					if(!ClientPrefs.lowQuality)
						upperBoppers.dance(true);

					bottomBoppers.dance(true);
					santa.dance(true);
				}

				switch (swagCounter)
				{
					case 0:
					    countdownThree = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownThree.scrollFactor.set();
						countdownThree.updateHitbox();

						if (PlayState.isPixelStage)
							countdownThree.setGraphicSize(Std.int(countdownThree.width * daPixelZoom));

						countdownThree.screenCenter();
						countdownThree.antialiasing = antialias;
						add(countdownThree);
						FlxTween.tween(countdownThree, {alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownThree);
								countdownThree.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownTwo = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownTwo.cameras = [camHUD];
						countdownTwo.scrollFactor.set();
						countdownTwo.updateHitbox();

						if (PlayState.isPixelStage)
							countdownTwo.setGraphicSize(Std.int(countdownTwo.width * daPixelZoom));

						countdownTwo.screenCenter();
						countdownTwo.antialiasing = antialias;
						insert(members.indexOf(notes), countdownTwo);
						FlxTween.tween(countdownTwo, {alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownTwo);
								countdownTwo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownOne = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownOne.cameras = [camHUD];
						countdownOne.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownOne.setGraphicSize(Std.int(countdownOne.width * daPixelZoom));

						countdownOne.screenCenter();
						countdownOne.antialiasing = antialias;
						insert(members.indexOf(notes), countdownOne);
						FlxTween.tween(countdownOne, {alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownOne);
								countdownOne.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						if (!PlayState.isPixelStage && (curStage != 'mall' || curStage != 'mallEvil' || curStage != 'limo')) {
							boyfriend.playAnim('pre-attack', true);
							boyfriend.specialAnim = true;
						}
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[3]));
						countdownGo.cameras = [camHUD];
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						insert(members.indexOf(notes), countdownGo);
						FlxTween.tween(countdownGo, {alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						if (!PlayState.isPixelStage || curStage != 'limo') {
							if(boyfriend.animOffsets.exists('hey')) {
								boyfriend.playAnim('hey', true);
								boyfriend.specialAnim = true;
								boyfriend.heyTimer = 0.6;
							}

							if(gf != null && gf.animOffsets.exists('cheer')) {
								gf.playAnim('cheer', true);
								gf.specialAnim = true;
								gf.heyTimer = 0.6;
							}
						}
				}

				notes.forEachAlive(function(note:Note) {
					if(ClientPrefs.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(ClientPrefs.middleScroll && !note.mustPress) {
							note.alpha *= 0.35;
						}
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
			}, 4);
		}
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad(obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.ignoreNote = true;

				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.ignoreNote = true;

				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function updateScore(miss:Bool = false)
	{
		switch (ClientPrefs.scoreTxtType)
		{
			case 'Default':
				if(ratingName == '?') {
					scoreTxt.text = 'NPS: ' + nps + ' (Max ' + maxNPS + ')'
					+ ' // Score: ' + songScore 
					+ ' // Combo Breaks: ' + songMisses 
					+ ' // Accuracy: ' + ratingName 
					+ ' // Rank: N/A';
				} else {
					scoreTxt.text = 'NPS: ' + nps + ' (Max ' + maxNPS + ')'
					+ ' // Score: ' + songScore 
					+ ' // Combo Breaks: ' + songMisses
					+ ' // Accuracy: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%'
					+ ' // Rank: ' + ratingName + ' (' + ratingFC + ')';
				}

			case 'Psych':
				scoreTxt.text = 'Score: ' + songScore
				+ ' | Misses: ' + songMisses
				+ ' | Rating: ' + ratingName
				+ (ratingName != '?' ? ' (${Highscore.floorDecimal(ratingPercent * 100, 2)}%) - $ratingFC' : '');

			case 'Kade':
				scoreTxt.text = 'NPS: ' + nps + ' (Max ' + maxNPS + ')' 
				+ ' | Score: ' + songScore 
				+ ' | Combo Breaks: ' + songMisses
				+ ' | Accuracy: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%'
				+ ' | ' + ratingFC + ratingName;

			case 'Simple':
				scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses;
		}

		if(ClientPrefs.scoreZoom && !miss && !cpuControlled)
		{
			if(scoreTxtTween != null) {
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
		}
		callOnLuas('onUpdateScore', [miss]);
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		if (!vocalsFinished){
			if (Conductor.songPosition <= vocals.length)
			{
				vocals.time = time;
				vocals.pitch = playbackRate;
			}
			vocals.play();
		}
		else
			vocals.time = vocals.length;

		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	public var songStarted = false;

	function startSong():Void
	{
		startingSong = false;
		songStarted = true;

		previousFrameTime = FlxG.game.ticks;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();
		vocals.onComplete = () -> vocalsFinished = true;

		if (useVideo)
			GlobalVideo.get().resume();

		if(startOnTime > 0)
			setSongTime(startOnTime - 500);

		startOnTime = 0;

		if(paused) {
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		switch(curStage)
		{
			case 'tank':
				if(!ClientPrefs.lowQuality) tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});
		}

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	
	public function lerpSongSpeed(num:Float, time:Float):Void
	{
		FlxTween.num(playbackRate, num, time, {onUpdate: function(tween:FlxTween){
			var ting = FlxMath.lerp(playbackRate, num, tween.percent);
			if (ting != 0) //divide by 0 is a verry bad
				playbackRate = ting; //why cant i just tween a variable

			FlxG.sound.music.time = Conductor.songPosition;
			resyncVocals();
		}});
	}
	
	var stair:Int = 0;
	private function generateSong():Void
	{
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		Conductor.changeBPM(SONG.bpm);

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		//generate the payload for the frontend
		bpPayload = ButtplugUtils.createPayload(Conductor.crochet);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = SONG.notes;

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if (MODS_ALLOWED && FUTURE_POLYMOD)
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				if (!randomMode && !flip && !stairs && !waves)
				{
					daNoteData = Std.int(songNotes[1] % 4);
				}
				if (oneK)
				{
					daNoteData = 2;
				}
				if (randomMode || randomMode && flip || randomMode && flip && stairs || randomMode && flip && stairs && waves) { //gotta specify that random mode must at least be turned on for this to work
					daNoteData = FlxG.random.int(0, 3);
				}
				if (flip && !stairs && !waves) {
					daNoteData = Std.int(Math.abs((songNotes[1] % 4) - 3));
				}
				if (stairs && !waves) {
					daNoteData = stair % 4;
					stair++;
				}
				if (waves) {
					switch (stair % 6)
					{
						case 0 | 1 | 2 | 3:
							daNoteData = stair % 6;
						case 4:
							daNoteData = 2;
						case 5:
							daNoteData = 1;
					}
					stair++;
				}

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				// sustain length fix courtesey of Stilic
				// modified by memehoovy
				swagNote.sustainLength = Math.round(songNotes[2] / Conductor.stepCrochet) * Conductor.stepCrochet;
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();

				unspawnNotes.push(swagNote);

				var roundSus:Int = Math.round(swagNote.sustainLength / Conductor.stepCrochet);
				if(roundSus > 0) {
					for (susNote in 0...Math.floor(Math.max(roundSus, 2)))
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);

						if (sustainNote.mustPress)
							sustainNote.x += FlxG.width / 2; // general offset
						else if(ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
						swagNote.x += FlxG.width / 2 + 25;
				}

				if(!noteTypes.contains(swagNote.noteType))
					noteTypes.push(swagNote.noteType);
			}
		}
		for (event in SONG.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);

		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

				if (boyfriend.antialiasing == true)
					boyfriend.antialiasing = ClientPrefs.globalAntialiasing;
				if (dad.antialiasing == true)
					dad.antialiasing = ClientPrefs.globalAntialiasing;
				if (gf.antialiasing == true)
			    		gf.antialiasing = ClientPrefs.globalAntialiasing;

			case 'Dadbattle Spotlight':
				if (curStage != 'stage')
					return;
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('stages/stage/spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;

				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				add(dadbattleLight);
				add(dadbattleSmokes);

				var offsetX = 200;
				var smoke:BGSprite = new BGSprite('stages/stage/smoke', -1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				dadbattleSmokes.add(smoke);
				var smoke:BGSprite = new BGSprite('stages/stage/smoke', 1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				dadbattleSmokes.add(smoke);

			case 'Philly Glow':
				if (curStage != 'philly')
					return;
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				insert(members.indexOf(phillyStreet), blammedLightsBlack);

				phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
				phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
				phillyWindowEvent.updateHitbox();
				phillyWindowEvent.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);

				phillyGlowGradient = new PhillyGlow.PhillyGlowGradient(-400, 225); //This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				if(!ClientPrefs.flashing) phillyGlowGradient.intendedAlpha = 0.7;

				precacheList.set('philly/particle', 'image'); //precache particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlow.PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
		}

		if(!eventsPushed.contains(event.event)) {
			eventsPushed.push(event.event);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	inline function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	inline function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			var targetAlpha:Float = 1;
			if (player < 1)
				targetAlpha = (!ClientPrefs.opponentStrums) ? 0 : (ClientPrefs.middleScroll) ? 0.35 : 1;

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
				babyArrow.alpha = targetAlpha;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
			{
				if(ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if(carTimer != null) carTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens)
				tween.active = false;
			for (timer in modchartTimers)
				timer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			if(carTimer != null) carTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}

			for (tween in modchartTweens)
				tween.active = true;
			for (timer in modchartTimers)
				timer.active = true;

			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer != null && startTimer.finished)
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			else
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			else
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null || vocalsFinished || isDead || !SONG.needsVoices) return;

		vocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	public var removedVideo = false;

	function truncateFloat(number:Float, precision:Int):Float 
	{
		var num = number;
		num = num * Math.pow(10, precision);
		num = Math.round( num ) / Math.pow(10, precision);
		return num;
	}

	override public function update(elapsed:Float)
	{
		// SECRET KEYS!! SHHHHHHHH
		#if debug
		final keyPressed:FlxKey = FlxG.keys.firstJustPressed();
		if (keyPressed != FlxKey.NONE){
			switch(keyPressed){
				case F1: // End Song
				if (!startingSong)
					endSong();
				case F2 if (!startingSong): // 10 Seconds Forward
					Conductor.songPosition += 10000;
					FlxG.sound.music.time = Conductor.songPosition;
					vocals.time = Conductor.songPosition;
				case F3 if (!startingSong): // 10 Seconds Back
					Conductor.songPosition -= 10000;
					FlxG.sound.music.time = Conductor.songPosition;
					vocals.time = Conductor.songPosition;
				case F4: // Enable/Disable Botplay
					if (!cpuControlled) {
						cpuControlled = true;
						botplayTxt.visible = true;
					} else {
						cpuControlled = false;
						botplayTxt.visible = false;
					}
				case F5: // Camera Speeds Up
					cameraSpeed += 0.5;
				case F6: // Camera Slows Down
					cameraSpeed -= 0.5;
				case F7: // Song Speeds Up
					songSpeed += 0.1;
				case F8: // Song Slows Down
					songSpeed -= 0.1;
				case F9: // Camera Zooms In
					defaultCamZoom += 0.1;
				case F10: // Camera Zooms Out
					defaultCamZoom -= 0.1;
				default:
					// nothing
			}
		}
		#end

		if (useVideo && GlobalVideo.get() != null)
		{
			if (GlobalVideo.get().ended && !removedVideo)
			{
				remove(videoSprite);
				removedVideo = true;
			}
		}

		callOnLuas('onUpdate', [elapsed]);

		switch (curStage)
		{
			case 'tank':
				moveTank(elapsed);
			case 'schoolEvil':
				if(!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished) {
					bgGhouls.visible = false;
				}
				Application.current.window.title = randomString();
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;

				if(phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.members.length-1;
					while (i > 0)
					{
						var particle = phillyGlowParticles.members[i];
						if(particle.alpha < 0)
						{
							particle.kill();
							phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}
						--i;
					}
				}
			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoParticles.forEach(function(spr:BGSprite) {
						if(spr.animation.curAnim.finished) {
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch(limoKillingState) {
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length) {
								if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170) {
									switch(i) {
										case 0 | 3:
											if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('stages/limo/gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('stages/limo/gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('stages/limo/gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('stages/limo/gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if(limoMetalPole.x > FlxG.width * 2) {
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x > FlxG.width * 1.5) {
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if(limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x < -275) {
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if(Math.round(bgLimo.x) == -150) {
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if(limoKillingState > 2) {
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length) {
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if(heyTimer > 0) {
					heyTimer -= elapsed;
					if(heyTimer <= 0) {
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		setOnLuas('curDecStep', curDecStep);
		setOnLuas('curDecBeat', curDecBeat);

		var pooper = npsArray.length - 1;
		while (pooper >= 0) {
			var fondler:Date = npsArray[pooper];
			if (fondler != null && fondler.getTime() + 1000 < Date.now().getTime()) {
				npsArray.remove(fondler);
			}
			else
				pooper = 0;
			pooper--;
		}
		nps = npsArray.length;
		if (nps > maxNPS)
			maxNPS = nps;

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', [], false);
			if(ret != FunkinLua.Function_Stop)
				openPauseMenu();
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
			openChartEditor();

		iconP1.alpha = healthBar.alpha;
		iconP2.alpha = healthBar.alpha;

		final iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		if (health > 2) 
			health = 2;

		switch (iconP1.widthThing) 
		{
			case 150:
				iconP1.animation.curAnim.curFrame = 0;
			case 300:
				if (healthBar.percent < 20)
					iconP1.animation.curAnim.curFrame = 1;
				else
					iconP1.animation.curAnim.curFrame = 0;
			case 450:
				if (healthBar.percent < 20)
					iconP1.animation.curAnim.curFrame = 1; //Losing
				else if (healthBar.percent > 20 && healthBar.percent < 80)
					iconP1.animation.curAnim.curFrame = 0; //Neutral
				else if (healthBar.percent > 80)
					iconP1.animation.curAnim.curFrame = 2; //Winning
			case 750:
				if (healthBar.percent < 20 && healthBar.percent > 0)
					iconP1.animation.curAnim.curFrame = 2; // Danger
				else if (healthBar.percent < 40 && healthBar.percent > 20)
					iconP1.animation.curAnim.curFrame = 1; // Losing
				else if (healthBar.percent > 40 && healthBar.percent < 60)
					iconP1.animation.curAnim.curFrame = 0; // Neutral
				else if (healthBar.percent > 60 && healthBar.percent < 80)
					iconP1.animation.curAnim.curFrame = 3; // Winning
				else if (healthBar.percent > 80)
					iconP1.animation.curAnim.curFrame = 4; // Victorious
		}

		// Does this work??
		// the 2 icons do, but idk about 3 nor the 5 icons
		switch (iconP2.widthThing) 
		{
			case 150:
				iconP2.animation.curAnim.curFrame = 0;
			case 300:
				if (healthBar.percent > 80)
					iconP2.animation.curAnim.curFrame = 1;
				else
					iconP2.animation.curAnim.curFrame = 0;
			case 450:
				if (healthBar.percent < 80)
					iconP2.animation.curAnim.curFrame = 2; //Winning
				else if (healthBar.percent > 20 && healthBar.percent < 80)
					iconP2.animation.curAnim.curFrame = 0; //Neutral
				else if (healthBar.percent > 20)
					iconP2.animation.curAnim.curFrame = 1; //Losing
			case 750:
				if (healthBar.percent < 80)
					iconP2.animation.curAnim.curFrame = 4; // Victorious
				else if (healthBar.percent < 60 && healthBar.percent > 80)
					iconP2.animation.curAnim.curFrame = 3; // Winning
				else if (healthBar.percent > 40 && healthBar.percent < 60)
					iconP2.animation.curAnim.curFrame = 0; // Neutral
				else if (healthBar.percent > 40 && healthBar.percent < 20)
					iconP2.animation.curAnim.curFrame = 1; // Losing
				else if (healthBar.percent < 20 && healthBar.percent > 0)
					iconP2.animation.curAnim.curFrame = 2; // Danger
		}

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}
		
		if (startedCountdown)
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else
		{
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}
		}

		FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));

		if (curBeat % 32 == 0 && randomSpeedThing)
		{
			var randomShit = FlxMath.roundDecimal(FlxG.random.float(0.4, 3), 2);
			lerpSongSpeed(randomShit, 1);
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			doDeathCheck(true);
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes.shift();
				notes.insert(0, dunceNote);
				dunceNote.spawned=true;
				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);
			}
		}

		if (generatedMusic && !inCutscene)
		{
			if(!cpuControlled)
				keyShit();
			else if(boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration 
			&& boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();

			if(startedCountdown)
			{
				var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
				notes.forEachAlive(function(daNote:Note)
				{
					var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
					if(!daNote.mustPress) strumGroup = opponentStrums;

					var strumX:Float = strumGroup.members[daNote.noteData].x;
					var strumY:Float = strumGroup.members[daNote.noteData].y;
					var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
					var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
					var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
					var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

					strumX += daNote.offsetX;
					strumY += daNote.offsetY;
					strumAngle += daNote.offsetAngle;
					strumAlpha *= daNote.multAlpha;

					// whether downscroll or not
					daNote.distance = ((strumScroll) ? 0.45 : -0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);

					var angleDir = strumDirection * Math.PI / 180;
					if (daNote.copyAngle)
						daNote.angle = strumDirection - 90 + strumAngle;

					if(daNote.copyAlpha)
						daNote.alpha = strumAlpha;

					if(daNote.copyX)
						daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

					if(daNote.copyY)
					{
						daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

						//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
						if(strumScroll && daNote.isSustainNote)
						{
							if (daNote.animation.curAnim.name.endsWith('end')) {
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
								if(PlayState.isPixelStage) {
									daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
								} else {
									daNote.y -= 19;
								}
							}
							daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
							daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
						}
					}

					if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
						opponentNoteHit(daNote);

					if(!daNote.blockHit && daNote.mustPress && cpuControlled && daNote.canBeHit) {
						if(daNote.isSustainNote) {
							if(daNote.canBeHit)
								goodNoteHit(daNote);
						} 
						else if(daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote)
							goodNoteHit(daNote);
					}

					var center:Float = strumY + Note.swagWidth / 2;
					if(strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
						(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						if (strumScroll)
						{
							if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;

								daNote.clipRect = swagRect;
							}
						}
						else
						{
							if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;

								daNote.clipRect = swagRect;
							}
						}
					}

					// Kill extremely late notes and cause misses
					if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
					{
						if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
							noteMiss(daNote);
						}
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
			}
			else
			{
				notes.forEachAlive(function(daNote:Note)
				{
					daNote.canBeHit = false;
					daNote.wasGoodHit = false;
				});
			}
		}
		checkEventNote();

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
	}

	function openPauseMenu()
	{
		persistentUpdate = false;
		persistentDraw = paused = true;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
		}
		if (inReplay)
			openSubState(new ReplayPauseSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		else
			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

		#if desktop
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		if (useVideo)
		{
			GlobalVideo.get().stop();
			remove(videoSprite);
			removedVideo = true;
		}

		persistentUpdate = false;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = paused = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', [], false);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = persistentDraw = false;
				for (tween in modchartTweens)
					tween.active = true;
				for (timer in modchartTimers)
					timer.active = true;

				if (SONG.song.toLowerCase() == 'tutorial')
					trace('bro how tf did you die on tutorial :skull:');
				
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y, 
					songScore, songMisses, Highscore.floorDecimal(ratingPercent * 100, 2), ratingName, ratingFC));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			if(Conductor.songPosition < eventNotes[0].strumTime) break;

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	inline public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Dadbattle Spotlight':
				if (curStage != 'stage')
					return;

				var val:Null<Int> = Std.parseInt(value1);
				if(val == null) val = 0;

				switch(Std.parseInt(value1))
				{
					case 1, 2, 3: //enable and target dad
						if(val == 1) //enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleSmokes.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if(val > 2) who = boyfriend;
						//2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer) {
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleSmokes, {alpha: 0}, 1, {onComplete: function(twn:FlxTween)
						{
							dadbattleSmokes.visible = false;
						}});
				}

			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if(curStage == 'mall') {
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;

			case 'Philly Glow':
				if (curStage != 'philly')
					return;

				var lightId:Int = Std.parseInt(value1);
				if(Math.isNaN(lightId)) lightId = 0;

				var doFlash:Void->Void = function() {
					var color:FlxColor = FlxColor.WHITE;
					if(!ClientPrefs.flashing) color.alphaFloat = 0.5;

					FlxG.camera.flash(color, 0.15, null, true);
				};

				var chars:Array<Character> = [boyfriend, gf, dad];
				switch(lightId)
				{
					case 0:
						if(phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;
							phillyWindowEvent.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
							curLightEvent = -1;

							for (who in chars)
							{
								who.color = FlxColor.WHITE;
							}
							phillyStreet.color = FlxColor.WHITE;
						}

					case 1: //turn on
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length-1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if(!phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
						}
						else if(ClientPrefs.flashing)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;
						if(!ClientPrefs.flashing) charColor.saturation *= 0.5;
						else charColor.saturation *= 0.75;

						for (who in chars)
						{
							who.color = charColor;
						}
						phillyGlowParticles.forEachAlive(function(particle:PhillyGlow.PhillyGlowParticle)
						{
							particle.color = color;
						});
						phillyGlowGradient.color = color;
						phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						phillyStreet.color = color;

					case 2: // spawn particles
						if(!ClientPrefs.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];
							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlow.PhillyGlowParticle = new PhillyGlow.PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
									phillyGlowParticles.add(particle);
								}
							}
						}
						phillyGlowGradient.bop();
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if(curStage == 'schoolEvil' && !ClientPrefs.lowQuality) {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if(camFollow != null)
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);
					if(Math.isNaN(val1)) val1 = 0;
					if(Math.isNaN(val2)) val2 = 0;

					isCameraOnForcedPos = false;
					if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
						camFollow.x = val1;
						camFollow.y = val2;
						isCameraOnForcedPos = true;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);
						setOnHscripts('boyfriend', boyfriend);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);
						setOnHscripts('dad', dad);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnLuas('gfName', gf.curCharacter);
							setOnHscripts('gf', gf);
						}
				}
				reloadHealthBarColors();

			case 'BG Freaks Expression':
				if(bgGirls != null) bgGirls.swapDanceType();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
					songSpeed = newValue;
				else
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {ease: FlxEase.linear, onComplete: _ -> songSpeedTween = null});

			case 'Popup':
				FlxG.sound.music.pause();
				vocals.pause();

				lime.app.Application.current.window.alert(value2, value1);
				FlxG.sound.music.resume();
				vocals.resume();

			case 'Popup (No Pause)':
				lime.app.Application.current.window.alert(value2, value1);

			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if(killMe.length > 1)
					FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], value2);
				else
					FunkinLua.setVarInArray(this, value1, value2);
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection():Void {
		if(SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			moveCamera(true, 1);
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		moveCamera(!SONG.notes[curSection].mustHitSection);
		callOnLuas('onMoveCamera', !SONG.notes[curSection].mustHitSection ? ['dad'] : ['boyfriend']);
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool, ?isGF:Int = 0)
	{
		//W: TODO, add the ability to disable camera movements per character
		if(isGF > 0){
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
		}
		else if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete: _ -> cameraTwn = null});
		}
	}

	inline function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3)
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete: _ -> cameraTwn = null});
	}

	inline function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}

	public var transitioning = false;

	public function endSong():Void
	{
		openfl.system.System.gc();

		ButtplugUtils.stop();

		if (useVideo)
		{
			GlobalVideo.get().stop();
			PlayState.instance.remove(PlayState.instance.videoSprite);
		}
		endBGVideo();

		#if sys
		if (!inReplay)
		{
			final files:Array<String> = CoolUtil.coolPathArray(Paths.getPreloadPath('replays/'));
			final song:String = SONG.song.coolSongFormatter().toLowerCase();
			var length:Null<Int> = null;

			length = (files == null) ? 0 : files.length;

			if (ClientPrefs.saveReplay)
				File.saveContent(Paths.getPreloadPath('replays/$song ${length}.json'), ReplayState.stringify());
		}
		#end

		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck())
				return;
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;
		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(
			[
				'week1_nomiss', 
				'week2_nomiss', 
				'week3_nomiss', 
				'week4_nomiss',
				'week5_nomiss', 
				'week6_nomiss', 
				'week7_nomiss', 
				'ur_bad',
				'ur_good', 
				'hype', 
				'two_keys', 
				'toastie', 
				'debugger'
			]);
			var customAchieve:String = checkForAchievement(achievementWeeks);

			if(achieve != null || customAchieve != null) {
				startAchievement(customAchieve != null ? customAchieve : achieve);
				return;
			}
		}
		#end

		var ret:Dynamic = callOnLuas('onEndSong', [], false);
		if(ret != FunkinLua.Function_Stop && !transitioning) {
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			playbackRate = 1;

			if (inReplay)
			{
				MusicBeatState.switchState(new FreeplayState());
				return;
			}
			else if (chartingMode)
			{
				openChartEditor();
				return;
			}
			else if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);
				if (storyPlaylist.length <= 0)
				{
					Mods.loadTheFirstEnabledMod();

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}

					new FlxTimer().start(0.5, function(tmr:FlxTimer) {
						persistentUpdate = true;
						openSubState(new ResultsSubState(sicks, goods, bads, shits, Std.int(campaignScore), Std.int(campaignMisses), 
							Highscore.floorDecimal(ratingPercent * 100, 2), ratingName, ratingFC)); 
					});

					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				Mods.loadTheFirstEnabledMod();
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				
				new FlxTimer().start(0.5, function(tmr:FlxTimer) {
					persistentUpdate = true;
					openSubState(new ResultsSubState(sicks, goods, bads, shits, songScore, songMisses,
				 		Highscore.floorDecimal(ratingPercent * 100, 2), ratingName, ratingFC)); 
				});
				
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = true;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	private function cachePopUpScore()
	{
		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';

		switch (ClientPrefs.uiSkin) 
		{
			case 'Default':
				pixelShitPart1 = (isPixelStage) ? 'pixelUI/' : '';
				pixelShitPart2 = (isPixelStage) ? '-pixel' : '';

			case 'Forever':
				pixelShitPart1 = 'skins/foreverUI/';
				pixelShitPart2 = (isPixelStage) ? '-pixel' : '';

			case 'Kade':
				pixelShitPart1 = 'skins/kadeUI/';
				pixelShitPart2 = (!isPixelStage) ? '' : '-pixel';

			// no pixel assets for simplylove oops
			// it isn't even meant for pixel stages anyways
			case 'Simplylove':
				pixelShitPart1 = 'skins/simplylove/';
				pixelShitPart2 = ''; 
		}

		Paths.image(pixelShitPart1 + "sick" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "good" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "bad" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "shit" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "combo" + pixelShitPart2);
		
		for (i in 0...10)
			Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2);
	}

	private function popUpScore(?note:Note, ?optionalRating:Float):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		vocals.volume = vocalsFinished ? 0 : 1;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		if (!inReplay)
		{
			ReplayState.hits.push(note.strumTime);
			ReplayState.judgements.push(noteDiff);
		}

		if (optionalRating != null)
			noteDiff = optionalRating;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.increase();
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashDisabled)
			spawnNoteSplashOnNote(note);

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';

		switch (ClientPrefs.uiSkin) 
		{
			case 'Default':
				pixelShitPart1 = (isPixelStage) ? 'pixelUI/' : '';
				pixelShitPart2 = (isPixelStage) ? '-pixel' : '';

			case 'Forever':
				pixelShitPart1 = 'skins/foreverUI/';
				pixelShitPart2 = (isPixelStage) ? '-pixel' : '';

			case 'Kade':
				pixelShitPart1 = 'skins/kadeUI/';
				pixelShitPart2 = (!isPixelStage) ? '' : '-pixel';

			case 'Simplylove':
				pixelShitPart1 = 'skins/simplylove/';
				pixelShitPart2 = '';
		}
		var ratingsGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
		final ratingsX:Float = FlxG.width * 0.35 - 40;
		final ratingsY:Float = 60;

		if (ratingsGroup.countDead() > 0) {
			rating = ratingsGroup.getFirstDead();
			rating.reset(ratingsX, ratingsY);
		} else {
			rating = new FlxSprite();
			ratingsGroup.add(rating);
		}
		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = ratingsX;
		rating.y -= ratingsY;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
		var comboSpr:FlxSprite;
		final comboX:Float = FlxG.width * 0.35;
		final comboY:Float = 60;
		if (comboGroup.countDead() > 0) {
			comboSpr = comboGroup.getFirstDead();
			comboSpr.reset(comboX, comboY);
		} else {
			comboSpr = new FlxSprite();
			comboGroup.add(comboSpr);
		}
		comboSpr.loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));	
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = comboX;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
		comboSpr.x += ClientPrefs.comboOffset[4];
		comboSpr.y -= ClientPrefs.comboOffset[5];
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
		
		if (!ClientPrefs.comboStacking)
		{
			if (lastRating != null) 
				lastRating.kill();
			lastRating = rating;
		}

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		// forever engine combo
		var seperatedScore:Array<String> = (combo + "").split("");
		var daLoop:Int = 0;

		if (!ClientPrefs.comboStacking)
		{
			if (lastCombo != null) lastCombo.kill();
			lastCombo = comboSpr;
		}
		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}
		for (i in seperatedScore)
		{
			var numScoreGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
			var numScore:FlxSprite;
			final numScoreX:Float = FlxG.width * 0.35 + (43 * daLoop) - 90;
			final numScoreY:Float = 80;
			if (numScoreGroup.countDead() > 0){
				numScore = numScoreGroup.getFirstDead();
				numScore.reset(numScoreX, numScoreY);
			}
			else{
				numScore = new FlxSprite();
				numScoreGroup.add(numScore);
			}
			numScore.loadGraphic(Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = numScoreX;
			numScore.y += numScoreY;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];
			
			if (!ClientPrefs.comboStacking)
				lastScore.push(numScore);

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));

			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = (!ClientPrefs.hideHud && showComboNum);

			if (curStage == 'limo') 
			{
				new FlxTimer().start(0.3, (tmr:FlxTimer) -> 
				{
					comboSpr.acceleration.x = 1250;
					rating.acceleration.x = 1250;
					numScore.acceleration.x = 1250;
				});
			}

			if (curStage == 'philly' && trainMoving && !trainFinishing) 
			{
				new FlxTimer().start(0.3, (tmr:FlxTimer) -> 
				{
					comboSpr.acceleration.x = -1250;
					rating.acceleration.x = -1250;
					numScore.acceleration.x = -1250;
				});
			}

			if(combo >= 0)
			{
				insert(members.indexOf(strumLineNotes), numScore);
			}
			if(combo >= 10)
			{
				insert(members.indexOf(strumLineNotes), comboSpr);
			}

			insert(members.indexOf(strumLineNotes), rating);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {onComplete: _ -> {
					numScore.kill();
					numScore.alpha = 1;
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
		}

		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {onComplete: _ -> {
				rating.kill();
				rating.alpha = 1;
			},
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {onComplete: _ -> {
				comboSpr.kill();
				comboSpr.alpha = 1;
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (!cpuControlled && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED)))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
					{
						if(daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}else{
					callOnLuas('onGhostTap', [key]);
					if (canMiss && !ClientPrefs.ghostTapping) {
						noteMissPress(key);
					}
				}

				// for the "Just the Two of Us" achievement
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && startedCountdown && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
		}
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys();

		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && parsedHoldArray[daNote.noteData] && daNote.canBeHit
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					goodNoteHit(daNote);
				}
			});

			if (parsedHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
			}
		}

		if(strumsBlocked.contains(true))
		{
			var parsedArray:Array<Bool> = parseKeys('_R');
			if(parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if(parsedArray[i] || strumsBlocked[i] == true)
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	inline private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		return [for (i in 0...controlArray.length) Reflect.getProperty(controls, controlArray[i] + suffix)];
	}

	public var useVideo = false;
	public static var webmHandler:WebmHandler;
	public var videoSprite:FlxSprite;

	public function backgroundVideo(source:String) // for background videos
	{
		#if WEBM_ALLOWED
		useVideo = true;

		var ourSource:String = "assets/videos/DO NOT DELETE OR GAME WILL CRASH/dontDelete.webm";
		var str1:String = "WEBM SHIT";
		webmHandler = new WebmHandler();
		webmHandler.source(ourSource);
		webmHandler.makePlayer();
		webmHandler.webm.name = str1;

		GlobalVideo.setWebm(webmHandler);

		GlobalVideo.get().source(source);
		GlobalVideo.get().clearPause();
		if (GlobalVideo.isWebm)
		{
			GlobalVideo.get().updatePlayer();
		}
		GlobalVideo.get().show();

		if (GlobalVideo.isWebm)
			GlobalVideo.get().restart();
		else
			GlobalVideo.get().play();

		var data = webmHandler.webm.bitmapData;

		videoSprite = new FlxSprite(-470, -30).loadGraphic(data);

		videoSprite.setGraphicSize(Std.int(videoSprite.width * 1.2));

		remove(gf);
		remove(boyfriend);
		remove(dad);
		add(videoSprite);
		add(gf);
		add(boyfriend);
		add(dad);

		trace('poggers');

		if (!songStarted)
			webmHandler.pause();
		else
			webmHandler.resume();
		#end
	}

	public function endBGVideo():Void
	{
		var video:Dynamic = BackgroundVideo.get();

		if (useVideo && video != null)
		{
			video.stop();
			remove(videoSprite);
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;
		health -= daNote.missHealth * healthLoss;
		
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		songMisses++;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10;

		totalPlayed++;
		RecalculateRating(true);

		var char:Character = boyfriend;
		if(daNote.gfNote) {
			char = gf;
		}

		if(char != null && !daNote.noMissAnimation && char.hasMissAnimations)
		{
			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daNote.animSuffix;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			if (!inReplay)
			{
				ReplayState.miss.push([Std.int(Conductor.songPosition), direction]);
			}
			
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating(true);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

			if(boyfriend.hasMissAnimations) {
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 0;
		}
		callOnLuas('noteMissPress', [direction]);
	}

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if(note.gfNote) {
				char = gf;
			}

			if(char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (SONG.needsVoices)
			vocals.volume = vocalsFinished ? 0 : 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)), time);
		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if (!note.isSustainNote)
				npsArray.unshift(Date.now());

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				if(!note.noMissAnimation)
				{
					switch(note.noteType) {
						case 'Hurt Note': //Hurt note
							if(boyfriend.animation.getByName('hurt') != null) {
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
					}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				if(combo > 9999) combo = 9999;
				popUpScore(note);
			}
			else if (!inReplay && note.isSustainNote)
			{
				ReplayState.sustainHits.push(Std.int(note.strumTime));
			}
			health += note.hitHealth * healthGain;

			if(!note.noAnimation) {
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if(note.gfNote)
				{
					if(gf != null)
					{
						gf.playAnim(animToPlay + note.animSuffix, true);
						gf.holdTimer = 0;
					}
				}
				else
				{
					boyfriend.playAnim(animToPlay + note.animSuffix, true);
					boyfriend.holdTimer = 0;
				}

				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)), time);
			} else {
				var spr = playerStrums.members[note.noteData];
				if(spr != null)
				{
					spr.playAnim('confirm', true);
				}
			}
			note.wasGoodHit = true;
			vocals.volume = vocalsFinished ? 0 : 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		var col:FlxColor = FlxColor.WHITE;
		if (data > -1 && data < ClientPrefs.arrowRGB.length)
		{
			col = ClientPrefs.arrowRGB[data][0];
			if(note != null) {
				col = note.noteSplashColor;
			}
		}

		if(note != null) {
			skin = note.noteSplashTexture;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, col);
		grpNoteSplashes.add(splash);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive()
	{
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			if (gf != null)
			{
				gf.playAnim('hairBlow');
				gf.specialAnim = true;
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		if(gf != null)
		{
			gf.danced = false; //Sets head to the correct position once the animation ends
			gf.playAnim('hairFall');
			gf.specialAnim = true;
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if(gf != null && gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function killHenchmen():Void
	{
		if(!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo') {
			if(limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
				var achieve:String = checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null) {
					startAchievement(achieve);
				} else {
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if(curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	function moveTank(?elapsed:Float = 0):Void
	{
		if(!inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}

	override function destroy() {
		for (lua in luaArray) {
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		#if HSCRIPT_ALLOWED
		for (i in hscriptMap.keys()) {
			callHscript(i, 'onDestroy', []);
			var hscript = hscriptMap.get(i);
			hscriptMap.remove(i);
			hscript = null;
		}
		hscriptMap.clear();
		#end

		#if cpp
		cpp.vm.Gc.enable(false);
		#end

		#if hscript
		if(FunkinLua.hscript != null) FunkinLua.hscript = null;
		#end

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;

		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat)
			return;

		if (generatedMusic)
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		iconP1.bounce();
		iconP2.bounce();

		if (curBeat % 2 == 0) {
			FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
			FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
		} else {
			FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
			FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
		}

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}

		switch (curStage)
		{
			case 'tank':
				if(!ClientPrefs.lowQuality) tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});

			case 'school':
				if(!ClientPrefs.lowQuality) {
					bgGirls.dance();
				}

			case 'mall':
				if(!ClientPrefs.lowQuality) {
					upperBoppers.dance(true);
				}

				if(heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);

			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}

		lastBeatHit = curBeat;

		if (dad.curCharacter.startsWith('spirit') && dad.animation.curAnim.name.startsWith('sing') && SONG.song.toLowerCase() == 'thorns')
		{
			FlxG.camera.shake(0.01, 0.1);
		}

		//buttplug fuckery
		if (ButtplugUtils.depsRunning) // so to not spam the console
			ButtplugUtils.sendPayload(bpPayload);

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
		}
		
		setOnLuas('curSection', curSection);
		callOnLuas('onSectionHit', []);
	}

	public function callOnScripts(event:String, args:Array<Dynamic>):Void
	{
		#if !SCRIPT_EXTENSION
		return;
		#end
		return for (i in scriptArray) i.call(event, args);
	}
	public function setOnScripts(key:String, value:Dynamic):Void
	{
		#if !SCRIPT_EXTENSION
		return;
		#end
		return for (i in scriptArray) i.set(key, value);
	}

	override public function callOnLuas(event:String, args:Array<Dynamic>, ?callOnScript:Bool, ignoreStops = true, exclusions:Array<String> = null):Dynamic {
		if (callOnScript)
			callOnScripts(event, args);

		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var ret:Dynamic = script.call(event, args);
			if(ret == FunkinLua.Function_StopLua && !ignoreStops)
				break;
			
			// had to do this because there is a bug in haxe where Stop != Continue doesnt work
			var bool:Bool = ret == FunkinLua.Function_Continue;
			if(!bool && ret != 0) {
				returnVal = cast ret;
			}
		}
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptMap.keys()) {
			var hscript = hscriptMap.get(script);
			if(hscript.closed || exclusions.contains(hscript.scriptName))
				continue;

			var ret:Dynamic = callHscript(script, event, args);
			if(ret == FunkinLua.Function_StopLua && !ignoreStops)
				break;

			if (ret != FunkinLua.Function_Continue)
				returnVal = ret;
		}
		#end

		for (i in achievementsArray)
		i.call(event, args);

		callStageFunctions(event, args);
			
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		setOnScripts(variable, arg);
		
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
		for(i in achievementsArray)
			i.set(variable, arg);

		#if HSCRIPT_ALLOWED
		setOnHscripts(variable, arg);
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	function StrumPress(id:Int, ?time:Float = 0)
	{
		var spr:StrumNote = playerStrums.members[id];
		spr.playAnim('pressed');
		spr.resetAnim = time == null ? 0 : time;
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', [], false);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

				// Rating Name
				switch (ClientPrefs.scoreTxtType)
				{
					case 'Default':
						if(ratingPercent >= 1)
						{
							ratingName = ratingStuff[ratingStuff.length - 1][0]; //Uses last string
						}
						else
						{
							for (i in 0...ratingStuff.length - 1)
							{
								if(ratingPercent < ratingStuff[i][1])
								{
									ratingName = ratingStuff[i][0];
									break;
								}
							}
						}

					case 'Psych':
						if(ratingPercent >= 1)
						{
							ratingName = psychRatings[psychRatings.length - 1][0]; //Uses last string
						}
						else
						{
							for (i in 0...psychRatings.length - 1)
							{
								if(ratingPercent < psychRatings[i][1])
								{
									ratingName = psychRatings[i][0];
									break;
								}
							}
						}

					case 'Kade':
						if(ratingPercent >= 1)
						{
							ratingName = kadeRatings[kadeRatings.length - 1][0]; //Uses last string
						}
						else
						{
							for (i in 0...kadeRatings.length - 1)
							{
								if(ratingPercent < kadeRatings[i][1])
								{
									ratingName = kadeRatings[i][0];
									break;
								}
							}
						}
				}
			}
			comboFunction();
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode || inReplay) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled && Achievements.exists(achievementName)) {
				var unlock:Bool = false;
				
				if (achievementName.contains(WeekData.getWeekFileName()) && achievementName.endsWith('nomiss')) // any FC achievements, name should be "weekFileName_nomiss", e.g: "weekd_nomiss";
				{
					if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						unlock = true;
				}
				switch(achievementName)
				{
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(!ClientPrefs.shaders && ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	var curLight:Int = -1;
	var curLightEvent:Int = -1;

	// messing with ur application window lmao
	static inline var upperCase:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	static inline var lowerCase:String = "abcdefghijklmnopqrstuvwxyz";
	static inline var numbers:String = "0123456789";
	static inline var symbols:String = "!@#$%&()*+-,./:;<=>?^[]{}";

	inline public static function randomString() 
	{
		var str = "";
			for (e in [upperCase, lowerCase, numbers, symbols])
				str += e.charAt(FlxG.random.int(0, e.length - 1));

		return str;
	}
}

class FunkinUtil  {

	static var utilInstance:MusicBeatState;
	static var playInstance:PlayState;
	static var isPlayState:Bool;

	public function new(inputInstance:MusicBeatState, ?isPlay:Bool = false){
		utilInstance = inputInstance;
		if(isPlay){
			playInstance = cast(inputInstance, PlayState);
			isPlayState = isPlay;
		}
	}

    public static inline function getInstance():FlxUIState
    {
        var dead:Bool = false;
        try{
			var obj:Dynamic = Reflect.getProperty(utilInstance, "isDead");
			if(obj != null){
            	dead = obj;
			}
        }
        catch(err){
            dead = false;
        }
        return dead ? cast(GameOverSubstate.instance, FlxUIState) : utilInstance;
    }

    public function funkyTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE) {
        if(isPlayState) playInstance.addTextToDebug(text, color);
        trace(text);
    }


    public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic):Any
    {
        var shit:Array<String> = variable.split('[');
        if(shit.length > 1)
        {
            var blah:Dynamic = Reflect.getProperty(instance, shit[0]);
            for (i in 1...shit.length)
            {
                var leNum:Dynamic = shit[i].substr(0, shit[i].length - 1);
                if(i >= shit.length-1) //Last array
                    blah[leNum] = value;
                else //Anything else
                    blah = blah[leNum];
            }
            return blah;
        }
        /*if(Std.isOfType(instance, Map))
            instance.set(variable,value);
        else*/

        Reflect.setProperty(instance, variable, value);
        return true;
    }
    public static function getVarInArray(instance:Dynamic, variable:String):Any
    {
        var shit:Array<String> = variable.split('[');
        if(shit.length > 1)
        {
            var blah:Dynamic = Reflect.getProperty(instance, shit[0]);
            for (i in 1...shit.length)
            {
                var leNum:Dynamic = shit[i].substr(0, shit[i].length - 1);
                blah = blah[leNum];
            }
            return blah;
        }

        return Reflect.getProperty(instance, variable);
    }

    inline static function getTextObject(name:String):FlxText
    {
        return utilInstance.modchartTexts.exists(name) ? utilInstance.modchartTexts.get(name) : Reflect.getProperty(PlayState.instance, name);
    }

    public function getShader(obj:String):FlxRuntimeShader
    {
        var killMe:Array<String> = obj.split('.');
        var leObj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(leObj != null) {
            var shader:Dynamic = leObj.shader;
            var shader:FlxRuntimeShader = shader;
            return shader;
        }
        return null;
    }

    function initLuaShaderHelper(name:String, ?glslVersion:Int = 120)
    {
        if(!ClientPrefs.shaders) return false;

        if(utilInstance.runtimeShaders.exists(name))
        {
            funkyTrace('Shader $name was already initialized!');
            return true;
        }

        var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
        if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
            foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));

        for(mod in Paths.getGlobalMods())
            foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));

        for (folder in foldersToCheck)
        {
            if(FileSystem.exists(folder))
            {
                var frag:String = folder + name + '.frag';
                var vert:String = folder + name + '.vert';
                var found:Bool = false;
                if(FileSystem.exists(frag))
                {
                    frag = File.getContent(frag);
                    found = true;
                }
                else frag = null;

                if (FileSystem.exists(vert))
                {
                    vert = File.getContent(vert);
                    found = true;
                }
                else vert = null;

                if(found)
                {
                    utilInstance.runtimeShaders.set(name, [frag, vert]);
                    //trace('Found shader $name!');
                    return true;
                }
            }
        }
        funkyTrace('Missing shader $name .frag AND .vert files!', false, false, FlxColor.RED);
        return false;
    }

    function getGroupStuff(leArray:Dynamic, variable:String) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			switch(Type.typeof(coverMeInPiss)){
				case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
					return coverMeInPiss.get(killMe[killMe.length-1]);
				default:
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
			};
		}
		switch(Type.typeof(leArray)){
			case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
				return leArray.get(variable);
			default:
				return Reflect.getProperty(leArray, variable);
		};
	}

	function loadFramesHelper(spr:FlxSprite, image:String, spriteType:String)
	{
		switch(spriteType.toLowerCase().trim())
		{
			case "texture" | "textureatlas" | "tex":
				spr.frames = AtlasFrameMaker.construct(image);

			case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
				spr.frames = AtlasFrameMaker.construct(image, null, true);

			case "packer" | "packeratlas" | "pac":
				spr.frames = Paths.getPackerAtlas(image);

			default:
				spr.frames = Paths.getSparrowAtlas(image);
		}
	}

	function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
			return;
		}
		Reflect.setProperty(leArray, variable, value);
	}

	function resetTextTag(tag:String) {
		if(!utilInstance.modchartTexts.exists(tag)) {
			return;
		}

		var pee:ModchartText = utilInstance.modchartTexts.get(tag);
		pee.kill();
		if(pee.wasAdded) {
			utilInstance.remove(pee, true);
		}
		pee.destroy();
		utilInstance.modchartTexts.remove(tag);
	}

	function resetSpriteTag(tag:String) {
		if(!utilInstance.modchartSprites.exists(tag)) {
			return;
		}

		var pee:ModchartSprite = utilInstance.modchartSprites.get(tag);
		pee.kill();
		if(pee.wasAdded) {
			utilInstance.remove(pee, true);
		}
		pee.destroy();
		utilInstance.modchartSprites.remove(tag);
	}

	function cancelTween(tag:String) {
		if(utilInstance.modchartTweens.exists(tag)) {
			utilInstance.modchartTweens.get(tag).cancel();
			utilInstance.modchartTweens.get(tag).destroy();
			utilInstance.modchartTweens.remove(tag);
		}
	}

	function tweenShit(tag:String, vars:String) {
		cancelTween(tag);
		var variables:Array<String> = vars.split('.');
		var sexyProp:Dynamic = getObjectDirectly(variables[0]);
		if(variables.length > 1) {
			sexyProp = getVarInArray(getPropertyLoopThingWhatever(variables), variables[variables.length-1]);
		}
		return sexyProp;
	}

	function cancelTimer(tag:String) {
		if(utilInstance.modchartTimers.exists(tag)) {
			var theTimer:FlxTimer = utilInstance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			utilInstance.modchartTimers.remove(tag);
		}
	}

	//Better optimized than using some getProperty shit or idk
	function getFlxEaseByString(?ease:String = '') {
		switch(ease.toLowerCase().trim()) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	function blendModeFromString(blend:String):BlendMode {
		switch(blend.toLowerCase().trim()) {
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'shader': return SHADER;
			case 'subtract': return SUBTRACT;
		}
		return NORMAL;
	}

	function cameraFromString(cam:String):FlxCamera {
		if(isPlayState){
			switch(cam.toLowerCase()) {
				case 'camhud' | 'hud': return playInstance.camHUD;
				case 'camother' | 'other': return playInstance.camOther;
			}
			return playInstance.camGame;
		}
		else{
			return utilInstance.camGame;
		}
	}

    static function addAnimByIndices(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false)
    {
        var strIndices:Array<String> = indices.trim().split(',');
        var die:Array<Int> = [];
        for (i in 0...strIndices.length) {
            die.push(Std.parseInt(strIndices[i]));
        }

        if(utilInstance.getLuaObject(obj, false)!=null) {
            var pussy:FlxSprite = utilInstance.getLuaObject(obj, false);
            pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);
            if(pussy.animation.curAnim == null) {
                pussy.animation.play(name, true);
            }
            return true;
        }

        var pussy:FlxSprite = Reflect.getProperty(getInstance(), obj);
        if(pussy != null) {
            pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);
            if(pussy.animation.curAnim == null) {
                pussy.animation.play(name, true);
            }
            return true;
        }
        return false;
    }

    public static function getPropertyLoopThingWhatever(killMe:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool=true):Dynamic
    {
        var coverMeInPiss:Dynamic = getObjectDirectly(killMe[0], checkForTextsToo);
        var end = killMe.length;
        if(getProperty)end=killMe.length-1;

        for (i in 1...end) {
            coverMeInPiss = getVarInArray(coverMeInPiss, killMe[i]);
        }
        return coverMeInPiss;
    }

    public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic
    {
        var coverMeInPiss:Dynamic = utilInstance.getLuaObject(objectName, checkForTextsToo);
        if(coverMeInPiss==null)
            coverMeInPiss = getVarInArray(getInstance(), objectName);

        return coverMeInPiss;
    }

    /*
    // Lua shit
    set('Function_StopLua', Function_StopLua);
    set('Function_Stop', Function_Stop);
    set('Function_Continue', Function_Continue);
    set('luaDebugMode', false);
    set('luaDeprecatedWarnings', true);
    set('inChartEditor', false);
    // Song/Week shit
    set('curBpm', Conductor.bpm);
    set('bpm', PlayState.SONG.bpm);
    set('scrollSpeed', PlayState.SONG.speed);
    set('crochet', Conductor.crochet);
    set('stepCrochet', Conductor.stepCrochet);
    set('songLength', FlxG.sound.music.length);
    set('songName', PlayState.SONG.song);
    set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
    set('startedCountdown', false);
    set('isStoryMode', PlayState.isStoryMode);
    set('difficulty', PlayState.storyDifficulty);
    var difficultyName:String = CoolUtil.difficulties[PlayState.storyDifficulty];
    set('difficultyName', difficultyName);
    set('difficultyPath', Paths.formatToSongPath(difficultyName));
    set('weekRaw', PlayState.storyWeek);
    set('week', WeekData.weeksList[PlayState.storyWeek]);
    set('seenCutscene', PlayState.seenCutscene);
    // Camera poo
    set('cameraX', 0);
    set('cameraY', 0);
    // Screen stuff
    set('screenWidth', FlxG.width);
    set('screenHeight', FlxG.height);
    // PlayState cringe ass nae nae bullcrap
    set('curBeat', 0);
    set('curStep', 0);
    set('curDecBeat', 0);
    set('curDecStep', 0);
    set('score', 0);
    set('misses', 0);
    set('hits', 0);
    set('rating', 0);
    set('ratingName', '');
    set('ratingFC', '');
    set('version', MainMenuState.psychEngineVersion.trim());
    set('inGameOver', false);
    set('mustHitSection', false);
    set('altAnim', false);
    set('gfSection', false);
    // Gameplay settings
    set('healthGainMult', utilInstance.healthGain);
    set('healthLossMult', utilInstance.healthLoss);
    set('instakillOnMiss', utilInstance.instakillOnMiss);
    set('botPlay', utilInstance.cpuControlled);
    set('practice', utilInstance.practiceMode);
    for (i in 0...4) {
        set('defaultPlayerStrumX' + i, 0);
        set('defaultPlayerStrumY' + i, 0);
        set('defaultOpponentStrumX' + i, 0);
        set('defaultOpponentStrumY' + i, 0);
    }
    // Default character positions woooo
    set('defaultBoyfriendX', utilInstance.BF_X);
    set('defaultBoyfriendY', utilInstance.BF_Y);
    set('defaultOpponentX', utilInstance.DAD_X);
    set('defaultOpponentY', utilInstance.DAD_Y);
    set('defaultGirlfriendX', utilInstance.GF_X);
    set('defaultGirlfriendY', utilInstance.GF_Y);
    // Character shit
    set('boyfriendName', PlayState.SONG.player1);
    set('dadName', PlayState.SONG.player2);
    set('gfName', PlayState.SONG.gfVersion);
    // Some settings, no jokes
    set('downscroll', ClientPrefs.downScroll);
    set('middlescroll', ClientPrefs.middleScroll);
    set('framerate', ClientPrefs.framerate);
    set('ghostTapping', ClientPrefs.ghostTapping);
    set('hideHud', ClientPrefs.hideHud);
    set('timeBarType', ClientPrefs.timeBarType);
    set('scoreZoom', ClientPrefs.scoreZoom);
    set('cameraZoomOnBeat', ClientPrefs.camZooms);
    set('flashingLights', ClientPrefs.flashing);
    set('noteOffset', ClientPrefs.noteOffset);
    set('healthBarAlpha', ClientPrefs.healthBarAlpha);
    set('noResetButton', ClientPrefs.noReset);
    set('lowQuality', ClientPrefs.lowQuality);
    set('shadersEnabled', ClientPrefs.shaders);
    set('scriptName', scriptName);
    set('currentModDirectory', Paths.currentModDirectory);
    #if windows
    set('buildTarget', 'windows');
    #elseif linux
    set('buildTarget', 'linux');
    #elseif mac
    set('buildTarget', 'mac');
    #elseif html5
    set('buildTarget', 'browser');
    #elseif android
    set('buildTarget', 'android');
    #else
    set('buildTarget', 'unknown');
    #end
    */
    //public function onCreate(){

    // shader shit
    public function initLuaShader(name:String, glslVersion:Int = 120) {
        if(!ClientPrefs.shaders) return false;

        #if (!flash && MODS_ALLOWED && sys)
        return initLuaShaderHelper(name, glslVersion);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
        return false;
    }

    public function setSpriteShader(obj:String, shader:String) {
        if(!ClientPrefs.shaders) return false;

        #if (!flash && MODS_ALLOWED && sys)
        if(!utilInstance.runtimeShaders.exists(shader) && !initLuaShaderHelper(shader))
        {
            funkyTrace('Shader $shader is missing!', false, false, FlxColor.RED);
            return false;
        }

        var killMe:Array<String> = obj.split('.');
        var leObj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(leObj != null) {
            var arr:Array<String> = utilInstance.runtimeShaders.get(shader);
            leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);
            return true;
        }
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
        return false;
    }
    public function removeSpriteShader(obj:String) {
        var killMe:Array<String> = obj.split('.');
        var leObj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(leObj != null) {
            leObj.shader = null;
            return true;
        }
        return false;
    }


    public function getShaderBool(obj:String, prop:String) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if (shader == null)
        {
            return null;
        }
        return shader.getBool(prop);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
    }
    public function getShaderBoolArray(obj:String, prop:String) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if (shader == null)
        {
            return null;
        }
        return shader.getBoolArray(prop);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
    }
    public function getShaderInt(obj:String, prop:String) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if (shader == null)
        {
            return null;
        }
        return shader.getInt(prop);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
    }
    public function getShaderIntArray(obj:String, prop:String) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if (shader == null)
        {
            return null;
        }
        return shader.getIntArray(prop);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
    }
    public function getShaderFloat(obj:String, prop:String) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if (shader == null)
        {
            return null;
        }
        return shader.getFloat(prop);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
    }
    public function getShaderFloatArray(obj:String, prop:String) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if (shader == null)
        {
            return null;
        }
        return shader.getFloatArray(prop);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
    }


    public function setShaderBool(obj:String, prop:String, value:Bool) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if(shader == null) return;

        shader.setBool(prop, value);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
    }
    public function setShaderBoolArray(obj:String, prop:String, values:Dynamic) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if(shader == null) return;

        shader.setBoolArray(prop, values);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
    }
    public function setShaderInt(obj:String, prop:String, value:Int) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if(shader == null) return;

        shader.setInt(prop, value);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
    }
    public function setShaderIntArray(obj:String, prop:String, values:Dynamic) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if(shader == null) return;

        shader.setIntArray(prop, values);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
    }
    public function setShaderFloat(obj:String, prop:String, value:Float) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if(shader == null) return;

        shader.setFloat(prop, value);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
    }
    public function setShaderFloatArray(obj:String, prop:String, values:Dynamic) {
        #if (!flash && MODS_ALLOWED && sys)
        var shader:FlxRuntimeShader = getShader(obj);
        if(shader == null) return;

        shader.setFloatArray(prop, values);
        #else
        funkyTrace("Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
    }


    //

    /*
    public function runHaxeCode(codeToRun:String) {
        #if hscript
        initHaxeInterp();
        try {
            var myFunction:Dynamic = haxeInterp.expr(new Parser().parseString(codeToRun));
            myFunction();
        }
        catch (e:Dynamic) {
            switch(e)
            {
                case 'Null Function Pointer', 'SReturn':
                    //nothing
                default:
                    funkyTrace(scriptName + ":" + lastCalledFunction + " - " + e, false, false, FlxColor.RED);
            }
        }
        #end
    }
    public function addHaxeLibrary(libName:String, ?libPackage:String = '') {
        #if hscript
        initHaxeInterp();
        try {
            var str:String = '';
            if(libPackage.length > 0)
                str = libPackage + '.';
            haxeInterp.variables.set(libName, Type.resolveClass(str + libName));
        }
        catch (e:Dynamic) {
            funkyTrace(scriptName + ":" + lastCalledFunction + " - " + e, false, false, FlxColor.RED);
        }
        #end
    }
    */

    public function loadSong(?name:String = null, ?difficultyNum:Int = -1) {
        if(isPlayState){
			if(name == null || name.length < 1)
				name = PlayState.SONG.song;
			if (difficultyNum == -1)
				difficultyNum = PlayState.storyDifficulty;

			var poop = Highscore.formatSong(name, difficultyNum);
			PlayState.SONG = Song.loadFromJson(poop, name);
			PlayState.storyDifficulty = difficultyNum;
			playInstance.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if(playInstance.vocals != null)
			{
				playInstance.vocals.pause();
				playInstance.vocals.volume = 0;
			}
		}
    }

    public function loadGraphic(variable:String, image:String, ?gridX:Int, ?gridY:Int) {
        var killMe:Array<String> = variable.split('.');
        var spr:FlxSprite = getObjectDirectly(killMe[0]);
        var gX = gridX==null?0:gridX;
        var gY = gridY==null?0:gridY;
        var animated = gX!=0 || gY!=0;

        if(killMe.length > 1) {
            spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(spr != null && image != null && image.length > 0)
        {
            spr.loadGraphic(Paths.image(image), animated, gX, gY);
        }
    }
    public function loadFrames(variable:String, image:String, spriteType:String = "sparrow") {
        var killMe:Array<String> = variable.split('.');
        var spr:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(spr != null && image != null && image.length > 0)
        {
            loadFramesHelper(spr, image, spriteType);
        }
    }

    // gay ass tweens
    public function doTweenX(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
        var penisExam:Dynamic = tweenShit(tag, vars);
        if(penisExam != null) {
            utilInstance.modchartTweens.set(tag, FlxTween.tween(penisExam, {x: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    utilInstance.callOnLuas('onTweenCompleted', [tag]);
                    utilInstance.modchartTweens.remove(tag);
                }
            }));
        } else {
            funkyTrace('Couldnt find object: ' + vars, false, false, FlxColor.RED);
        }
    }
    public function doTweenY(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
        var penisExam:Dynamic = tweenShit(tag, vars);
        if(penisExam != null) {
            utilInstance.modchartTweens.set(tag, FlxTween.tween(penisExam, {y: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    utilInstance.callOnLuas('onTweenCompleted', [tag]);
                    utilInstance.modchartTweens.remove(tag);
                }
            }));
        } else {
            funkyTrace('Couldnt find object: ' + vars, false, false, FlxColor.RED);
        }
    }
    public function doTweenAngle(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
        var penisExam:Dynamic = tweenShit(tag, vars);
        if(penisExam != null) {
            utilInstance.modchartTweens.set(tag, FlxTween.tween(penisExam, {angle: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    utilInstance.callOnLuas('onTweenCompleted', [tag]);
                    utilInstance.modchartTweens.remove(tag);
                }
            }));
        } else {
            funkyTrace('Couldnt find object: ' + vars, false, false, FlxColor.RED);
        }
    }
    public function doTweenAlpha(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
        var penisExam:Dynamic = tweenShit(tag, vars);
        if(penisExam != null) {
            utilInstance.modchartTweens.set(tag, FlxTween.tween(penisExam, {alpha: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    utilInstance.callOnLuas('onTweenCompleted', [tag]);
                    utilInstance.modchartTweens.remove(tag);
                }
            }));
        } else {
            funkyTrace('Couldnt find object: ' + vars, false, false, FlxColor.RED);
        }
    }
    public function doTweenZoom(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
        var penisExam:Dynamic = tweenShit(tag, vars);
        if(penisExam != null) {
            utilInstance.modchartTweens.set(tag, FlxTween.tween(penisExam, {zoom: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    utilInstance.callOnLuas('onTweenCompleted', [tag]);
                    utilInstance.modchartTweens.remove(tag);
                }
            }));
        } else {
            funkyTrace('Couldnt find object: ' + vars, false, false, FlxColor.RED);
        }
    }
    public function doTweenColor(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
        var penisExam:Dynamic = tweenShit(tag, vars);
        if(penisExam != null) {
            var color:Int = Std.parseInt(targetColor);
            if(!targetColor.startsWith('0x')) color = Std.parseInt('0xff' + targetColor);

            var curColor:FlxColor = penisExam.color;
            curColor.alphaFloat = penisExam.alpha;
            utilInstance.modchartTweens.set(tag, FlxTween.color(penisExam, duration, curColor, color, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    utilInstance.modchartTweens.remove(tag);
                    utilInstance.callOnLuas('onTweenCompleted', [tag]);
                }
            }));
        } else {
            funkyTrace('Couldnt find object: ' + vars, false, false, FlxColor.RED);
        }
    }

    //Tween shit, but for strums
    public function noteTweenX(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
        if(!isPlayState) return;
		cancelTween(tag);
        if(note < 0) note = 0;
        var testicle:StrumNote = playInstance.strumLineNotes.members[note % playInstance.strumLineNotes.length];

        if(testicle != null) {
            playInstance.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    playInstance.callOnLuas('onTweenCompleted', [tag]);
                    playInstance.modchartTweens.remove(tag);
                }
            }));
        }
    }
    public function noteTweenY(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
        if(!isPlayState) return;
		cancelTween(tag);
        if(note < 0) note = 0;
        var testicle:StrumNote = playInstance.strumLineNotes.members[note % playInstance.strumLineNotes.length];

        if(testicle != null) {
            playInstance.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    playInstance.callOnLuas('onTweenCompleted', [tag]);
                    playInstance.modchartTweens.remove(tag);
                }
            }));
        }
    }

    public function noteTweenDirection(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
        if(!isPlayState) return;
		cancelTween(tag);
        if(note < 0) note = 0;
        var testicle:StrumNote = playInstance.strumLineNotes.members[note % playInstance.strumLineNotes.length];

        if(testicle != null) {
            playInstance.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    playInstance.callOnLuas('onTweenCompleted', [tag]);
                    playInstance.modchartTweens.remove(tag);
                }
            }));
        }
    }
    public function mouseClicked(button:String) {
        var boobs = FlxG.mouse.justPressed;
        switch(button){
            case 'middle':
                boobs = FlxG.mouse.justPressedMiddle;
            case 'right':
                boobs = FlxG.mouse.justPressedRight;
        }


        return boobs;
    }
    public function mousePressed(button:String) {
        var boobs = FlxG.mouse.pressed;
        switch(button){
            case 'middle':
                boobs = FlxG.mouse.pressedMiddle;
            case 'right':
                boobs = FlxG.mouse.pressedRight;
        }
        return boobs;
    }
    public function mouseReleased(button:String) {
        var boobs = FlxG.mouse.justReleased;
        switch(button){
            case 'middle':
                boobs = FlxG.mouse.justReleasedMiddle;
            case 'right':
                boobs = FlxG.mouse.justReleasedRight;
        }
        return boobs;
    }
    public function noteTweenAngle(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
        if(!isPlayState) return;
		cancelTween(tag);
        if(note < 0) note = 0;
        var testicle:StrumNote = playInstance.strumLineNotes.members[note % playInstance.strumLineNotes.length];

        if(testicle != null) {
            playInstance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    playInstance.callOnLuas('onTweenCompleted', [tag]);
                    playInstance.modchartTweens.remove(tag);
                }
            }));
        }
    }
    public function noteTweenAlpha(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
        if(!isPlayState) return;
		cancelTween(tag);
        if(note < 0) note = 0;
        var testicle:StrumNote = playInstance.strumLineNotes.members[note % playInstance.strumLineNotes.length];

        if(testicle != null) {
            playInstance.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration, {ease: getFlxEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                    playInstance.callOnLuas('onTweenCompleted', [tag]);
                    playInstance.modchartTweens.remove(tag);
                }
            }));
        }
    }


    public function runTimer(tag:String, time:Float = 1, loops:Int = 1) {
        cancelTimer(tag);
        utilInstance.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
            if(tmr.finished) {
                utilInstance.modchartTimers.remove(tag);
            }
            utilInstance.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
            //trace('Timer Completed: ' + tag);
        }, loops));
    }


    /*public function getPropertyAdvanced(varsStr:String) {
        var variables:Array<String> = varsStr.replace(' ', '').split(',');
        var leClass:Class<Dynamic> = Type.resolveClass(variables[0]);
        if(variables.length > 2) {
            var curProp:Dynamic = Reflect.getProperty(leClass, variables[1]);
            if(variables.length > 3) {
                for (i in 2...variables.length-1) {
                    curProp = Reflect.getProperty(curProp, variables[i]);
                }
            }
            return Reflect.getProperty(curProp, variables[variables.length-1]);
        } else if(variables.length == 2) {
            return Reflect.getProperty(leClass, variables[variables.length-1]);
        }
        return null;
    }
    public function setPropertyAdvanced(varsStr:String, value:Dynamic) {
        var variables:Array<String> = varsStr.replace(' ', '').split(',');
        var leClass:Class<Dynamic> = Type.resolveClass(variables[0]);
        if(variables.length > 2) {
            var curProp:Dynamic = Reflect.getProperty(leClass, variables[1]);
            if(variables.length > 3) {
                for (i in 2...variables.length-1) {
                    curProp = Reflect.getProperty(curProp, variables[i]);
                }
            }
            return Reflect.setProperty(curProp, variables[variables.length-1], value);
        } else if(variables.length == 2) {
            return Reflect.setProperty(leClass, variables[variables.length-1], value);
        }
    }*/

    //stupid bietch ass functions
    public function addScore(value:Int = 0) {
		if(!isPlayState) return;
        playInstance.songScore += value;
        playInstance.RecalculateRating();
    }
    public function addMisses(value:Int = 0) {
        if(!isPlayState) return;
        playInstance.songMisses += value;
        playInstance.RecalculateRating();
    }
    public function addHits(value:Int = 0) {
        if(!isPlayState) return;
        playInstance.songHits += value;
        playInstance.RecalculateRating();
    }
    public function setScore(value:Int = 0) {
        if(!isPlayState) return;
        playInstance.songScore = value;
        playInstance.RecalculateRating();
    }
    public function setMisses(value:Int = 0) {
        if(!isPlayState) return;
        playInstance.songMisses = value;
        playInstance.RecalculateRating();
    }
    public function setHits(value:Int = 0) {
        if(!isPlayState) return;
        playInstance.songHits = value;
        playInstance.RecalculateRating();
    }
    public function getScore():Int {
        if(!isPlayState) return 0;
        return playInstance.songScore;
    }
    public function getMisses():Int {
        if(!isPlayState) return 0;
        return playInstance.songMisses;
    }
    public function getHits():Int {
        if(!isPlayState) return 0;
        return playInstance.songHits;
    }

    public function setHealth(value:Float = 0) {
        if(!isPlayState) return;
        playInstance.health = value;
    }
    public function addHealth(value:Float = 0) {
        if(!isPlayState) return;
        playInstance.health += value;
    }
    public function getHealth():Float {
        if(!isPlayState) return -1.0;
        return playInstance.health;
    }

    public function getColorFromHex(color:String) {
        if(!color.startsWith('0x')) color = '0xff' + color;
        return Std.parseInt(color);
    }

    public function keyboardJustPressed(name:String)
    {
        return Reflect.getProperty(FlxG.keys.justPressed, name);
    }
    public function keyboardPressed(name:String)
    {
        return Reflect.getProperty(FlxG.keys.pressed, name);
    }
    public function keyboardReleased(name:String)
    {
        return Reflect.getProperty(FlxG.keys.justReleased, name);
    }

    public function anyGamepadJustPressed(name:String)
    {
        return FlxG.gamepads.anyJustPressed(name);
    }
    public function anyGamepadPressed(name:String)
    {
        return FlxG.gamepads.anyPressed(name);
    }
    public function anyGamepadReleased(name:String)
    {
        return FlxG.gamepads.anyJustReleased(name);
    }

    public function gamepadAnalogX(id:Int, ?leftStick:Bool = true)
    {
        var controller = FlxG.gamepads.getByID(id);
        if (controller == null)
        {
            return 0.0;
        }
        return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
    }
    public function gamepadAnalogY(id:Int, ?leftStick:Bool = true)
    {
        var controller = FlxG.gamepads.getByID(id);
        if (controller == null)
        {
            return 0.0;
        }
        return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
    }
    public function gamepadJustPressed(id:Int, name:String)
    {
        var controller = FlxG.gamepads.getByID(id);
        if (controller == null)
        {
            return false;
        }
        return Reflect.getProperty(controller.justPressed, name) == true;
    }
    public function gamepadPressed(id:Int, name:String)
    {
        var controller = FlxG.gamepads.getByID(id);
        if (controller == null)
        {
            return false;
        }
        return Reflect.getProperty(controller.pressed, name) == true;
    }
    public function gamepadReleased(id:Int, name:String)
    {
        var controller = FlxG.gamepads.getByID(id);
        if (controller == null)
        {
            return false;
        }
        return Reflect.getProperty(controller.justReleased, name) == true;
    }

    public function keyJustPressed(name:String) {
        var key:Bool = false;
        switch(name) {
            case 'left': key = utilInstance.getControl('NOTE_LEFT_P');
            case 'down': key = utilInstance.getControl('NOTE_DOWN_P');
            case 'up': key = utilInstance.getControl('NOTE_UP_P');
            case 'right': key = utilInstance.getControl('NOTE_RIGHT_P');
            case 'accept': key = utilInstance.getControl('ACCEPT');
            case 'back': key = utilInstance.getControl('BACK');
            case 'pause': key = utilInstance.getControl('PAUSE');
            case 'reset': key = utilInstance.getControl('RESET');
            case 'space': key = FlxG.keys.justPressed.SPACE;//an extra key for convinience
        }
        return key;
    }
    public function keyPressed(name:String) {
        var key:Bool = false;
        switch(name) {
            case 'left': key = utilInstance.getControl('NOTE_LEFT');
            case 'down': key = utilInstance.getControl('NOTE_DOWN');
            case 'up': key = utilInstance.getControl('NOTE_UP');
            case 'right': key = utilInstance.getControl('NOTE_RIGHT');
            case 'space': key = FlxG.keys.pressed.SPACE;//an extra key for convinience
        }
        return key;
    }
    public function keyReleased(name:String) {
        var key:Bool = false;
        switch(name) {
            case 'left': key = utilInstance.getControl('NOTE_LEFT_R');
            case 'down': key = utilInstance.getControl('NOTE_DOWN_R');
            case 'up': key = utilInstance.getControl('NOTE_UP_R');
            case 'right': key = utilInstance.getControl('NOTE_RIGHT_R');
            case 'space': key = FlxG.keys.justReleased.SPACE;//an extra key for convinience
        }
        return key;
    }
    public function addCharacterToList(name:String, type:String) {
        if(!isPlayState) return;
		var charType:Int = 0;
        switch(type.toLowerCase()) {
            case 'dad': charType = 1;
            case 'gf' | 'girlfriend': charType = 2;
        }
        playInstance.addCharacterToList(name, charType);
    }
    public function precacheImage(name:String) {
        Paths.returnGraphic(name);
    }
    public function precacheSound(name:String) {
        CoolUtil.precacheSound(name);
    }
    public function precacheMusic(name:String) {
        CoolUtil.precacheMusic(name);
    }
    public function triggerEvent(name:String, arg1:Dynamic, arg2:Dynamic) {
        if(!isPlayState) return true;
		var value1:String = arg1;
        var value2:String = arg2;
        playInstance.triggerEventNote(name, value1, value2);
        //trace('Triggered event: ' + name + ', ' + value1 + ', ' + value2);
        return true;
    }

    public function startCountdown() {
        if(!isPlayState) return true;
		playInstance.startCountdown();
        return true;
    }
    public function endSong() {
        if(!isPlayState) return true;
		playInstance.KillNotes();
        playInstance.endSong();
        return true;
    }
    public function restartSong(?skipTransition:Bool = false) {
        utilInstance.persistentUpdate = false;
        PauseSubState.restartSong(skipTransition);
        return true;
    }
    public function exitSong(?skipTransition:Bool = false) {
        if(!isPlayState) return true;
		if(skipTransition)
        {
            FlxTransitionableState.skipNextTransIn = true;
            FlxTransitionableState.skipNextTransOut = true;
        }

        PlayState.cancelMusicFadeTween();
        CustomFadeTransition.nextCamera = playInstance.camOther;
        if(FlxTransitionableState.skipNextTransIn)
            CustomFadeTransition.nextCamera = null;

        if(PlayState.isStoryMode)
            MusicBeatState.switchState(new StoryMenuState());
        else
            MusicBeatState.switchState(new FreeplayState());

        FlxG.sound.playMusic(Paths.music('freakyMenu'));
        PlayState.changedDifficulty = false;
        PlayState.chartingMode = false;
        playInstance.transitioning = true;
        WeekData.loadTheFirstEnabledMod();
        return true;
    }
    public function getSongPosition() {
        return Conductor.songPosition;
    }

    public function getCharacterX(type:String) {
        switch(type.toLowerCase()) {
            case 'dad' | 'opponent':
                return playInstance.dadGroup.x;
            case 'gf' | 'girlfriend':
                return playInstance.gfGroup.x;
            default:
                return playInstance.boyfriendGroup.x;
        }
    }
    public function setCharacterX(type:String, value:Float) {
        switch(type.toLowerCase()) {
            case 'dad' | 'opponent':
                playInstance.dadGroup.x = value;
            case 'gf' | 'girlfriend':
                playInstance.gfGroup.x = value;
            default:
                playInstance.boyfriendGroup.x = value;
        }
    }
    public function getCharacterY(type:String) {
        switch(type.toLowerCase()) {
            case 'dad' | 'opponent':
                return playInstance.dadGroup.y;
            case 'gf' | 'girlfriend':
                return playInstance.gfGroup.y;
            default:
                return playInstance.boyfriendGroup.y;
        }
    }
    public function setCharacterY(type:String, value:Float) {
        switch(type.toLowerCase()) {
            case 'dad' | 'opponent':
                playInstance.dadGroup.y = value;
            case 'gf' | 'girlfriend':
                playInstance.gfGroup.y = value;
            default:
                playInstance.boyfriendGroup.y = value;
        }
    }
    public function cameraSetTarget(target:String) {
        var isDad:Bool = false;
        if(target == 'dad') {
            isDad = true;
        }
        playInstance.moveCamera(isDad);
        return isDad;
    }
    public function cameraShake(camera:String, intensity:Float, duration:Float) {
        cameraFromString(camera).shake(intensity, duration);
    }

    public function cameraFlash(camera:String, color:String, duration:Float,forced:Bool) {
        var colorNum:Int = Std.parseInt(color);
        if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
        cameraFromString(camera).flash(colorNum, duration,null,forced);
    }
    public function cameraFade(camera:String, color:String, duration:Float,forced:Bool) {
        var colorNum:Int = Std.parseInt(color);
        if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
        cameraFromString(camera).fade(colorNum, duration,false,null,forced);
    }
    public function setRatingPercent(value:Float) {
        playInstance.ratingPercent = value;
    }
    public function setRatingName(value:String) {
        playInstance.ratingName = value;
    }
    public function setRatingFC(value:String) {
        playInstance.ratingFC = value;
    }
    public function getMouseX(camera:String) {
        var cam:FlxCamera = cameraFromString(camera);
        return FlxG.mouse.getScreenPosition(cam).x;
    }
    public function getMouseY(camera:String) {
        var cam:FlxCamera = cameraFromString(camera);
        return FlxG.mouse.getScreenPosition(cam).y;
    }

    public function getMidpointX(variable:String) {
        var killMe:Array<String> = variable.split('.');
        var obj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }
        if(obj != null) return obj.getMidpoint().x;

        return 0;
    }
    public function getMidpointY(variable:String) {
        var killMe:Array<String> = variable.split('.');
        var obj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }
        if(obj != null) return obj.getMidpoint().y;

        return 0;
    }
    public function getGraphicMidpointX(variable:String) {
        var killMe:Array<String> = variable.split('.');
        var obj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }
        if(obj != null) return obj.getGraphicMidpoint().x;

        return 0;
    }
    public function getGraphicMidpointY(variable:String) {
        var killMe:Array<String> = variable.split('.');
        var obj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }
        if(obj != null) return obj.getGraphicMidpoint().y;

        return 0;
    }
    public function getScreenPositionX(variable:String) {
        var killMe:Array<String> = variable.split('.');
        var obj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }
        if(obj != null) return obj.getScreenPosition().x;

        return 0;
    }
    public function getScreenPositionY(variable:String) {
        var killMe:Array<String> = variable.split('.');
        var obj:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            obj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }
        if(obj != null) return obj.getScreenPosition().y;

        return 0;
    }
    public function characterDance(character:String) {
        if(!isPlayState) return;
		switch(character.toLowerCase()) {
            case 'dad': playInstance.dad.dance();
            case 'gf' | 'girlfriend': if(playInstance.gf != null) playInstance.gf.dance();
            default: playInstance.boyfriend.dance();
        }
    }

    public function makeLuaSprite(tag:String, image:String, x:Float, y:Float) {
        tag = tag.replace('.', '');
        resetSpriteTag(tag);
        var leSprite:ModchartSprite = new ModchartSprite(x, y);
        if(image != null && image.length > 0)
        {
            leSprite.loadGraphic(Paths.image(image));
        }
        leSprite.antialiasing = ClientPrefs.globalAntialiasing;
        utilInstance.modchartSprites.set(tag, leSprite);
        leSprite.active = true;
    }
    public function makeAnimatedLuaSprite(tag:String, image:String, x:Float, y:Float, ?spriteType:String = "sparrow") {
        tag = tag.replace('.', '');
        resetSpriteTag(tag);
        var leSprite:ModchartSprite = new ModchartSprite(x, y);

        loadFramesHelper(leSprite, image, spriteType);
        leSprite.antialiasing = ClientPrefs.globalAntialiasing;
        utilInstance.modchartSprites.set(tag, leSprite);
    }

    public function makeGraphic(obj:String, width:Int, height:Int, color:String) {
        var colorNum:Int = Std.parseInt(color);
        if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

        var spr:FlxSprite = utilInstance.getLuaObject(obj,false);
        if(spr!=null) {
            utilInstance.getLuaObject(obj,false).makeGraphic(width, height, colorNum);
            return;
        }

        var object:FlxSprite = Reflect.getProperty(getInstance(), obj);
        if(object != null) {
            object.makeGraphic(width, height, colorNum);
        }
    }
    public function addAnimationByPrefix(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
        if(utilInstance.getLuaObject(obj,false)!=null) {
            var cock:FlxSprite = utilInstance.getLuaObject(obj,false);
            cock.animation.addByPrefix(name, prefix, framerate, loop);
            if(cock.animation.curAnim == null) {
                cock.animation.play(name, true);
            }
            return;
        }

        var cock:FlxSprite = Reflect.getProperty(getInstance(), obj);
        if(cock != null) {
            cock.animation.addByPrefix(name, prefix, framerate, loop);
            if(cock.animation.curAnim == null) {
                cock.animation.play(name, true);
            }
        }
    }

    public function addAnimation(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true) {
        if(utilInstance.getLuaObject(obj,false)!=null) {
            var cock:FlxSprite = utilInstance.getLuaObject(obj,false);
            cock.animation.add(name, frames, framerate, loop);
            if(cock.animation.curAnim == null) {
                cock.animation.play(name, true);
            }
            return;
        }

        var cock:FlxSprite = Reflect.getProperty(getInstance(), obj);
        if(cock != null) {
            cock.animation.add(name, frames, framerate, loop);
            if(cock.animation.curAnim == null) {
                cock.animation.play(name, true);
            }
        }
    }

    public function addAnimationByIndices(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
        return addAnimByIndices(obj, name, prefix, indices, framerate, false);
    }
    public function addAnimationByIndicesLoop(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
        return addAnimByIndices(obj, name, prefix, indices, framerate, true);
    }


    public function playAnim(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
    {
        if(utilInstance.getLuaObject(obj, false) != null) {
            var luaObj:FlxSprite = utilInstance.getLuaObject(obj,false);
            if(luaObj.animation.getByName(name) != null)
            {
                luaObj.animation.play(name, forced, reverse, startFrame);
                if(Std.isOfType(luaObj, ModchartSprite))
                {
                    //convert luaObj to ModchartSprite
                    var obj:Dynamic = luaObj;
                    var luaObj:ModchartSprite = obj;

                    var daOffset = luaObj.animOffsets.get(name);
                    if (luaObj.animOffsets.exists(name))
                    {
                        luaObj.offset.set(daOffset[0], daOffset[1]);
                    }
                    else
                        luaObj.offset.set(0, 0);
                }
            }
            return true;
        }

        var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
        if(spr != null) {
            if(spr.animation.getByName(name) != null)
            {
                if(Std.isOfType(spr, Character))
                {
                    //convert spr to Character
                    var obj:Dynamic = spr;
                    var spr:Character = obj;
                    spr.playAnim(name, forced, reverse, startFrame);
                }
                else
                    spr.animation.play(name, forced, reverse, startFrame);
            }
            return true;
        }
        return false;
    }
    public function addOffset(obj:String, anim:String, x:Float, y:Float) {
        if(utilInstance.modchartSprites.exists(obj)) {
            utilInstance.modchartSprites.get(obj).animOffsets.set(anim, [x, y]);
            return true;
        }

        var char:Character = Reflect.getProperty(getInstance(), obj);
        if(char != null) {
            char.addOffset(anim, x, y);
            return true;
        }
        return false;
    }

    public function setScrollFactor(obj:String, scrollX:Float, scrollY:Float) {
        if(utilInstance.getLuaObject(obj,false)!=null) {
            utilInstance.getLuaObject(obj,false).scrollFactor.set(scrollX, scrollY);
            return;
        }

        var object:FlxObject = Reflect.getProperty(getInstance(), obj);
        if(object != null) {
            object.scrollFactor.set(scrollX, scrollY);
        }
    }
    public function addLuaSprite(tag:String, front:Bool = false) {
        if(utilInstance.modchartSprites.exists(tag)) {
            var shit:ModchartSprite = utilInstance.modchartSprites.get(tag);
            if(!shit.wasAdded) {
                if(!isPlayState || front )
                {
                    getInstance().add(shit);
                }
                else
                {
					if(playInstance.isDead)
                    {
                        GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
                    }
                    else
                    {
                        var position:Int = utilInstance.members.indexOf(playInstance.gfGroup);
                        if(utilInstance.members.indexOf(playInstance.boyfriendGroup) < position) {
                            position = utilInstance.members.indexOf(playInstance.boyfriendGroup);
                        } else if(utilInstance.members.indexOf(playInstance.dadGroup) < position) {
                            position = utilInstance.members.indexOf(playInstance.dadGroup);
                        }
                        playInstance.insert(position, shit);
                    }
                }
                shit.wasAdded = true;
                //trace('added a thing: ' + tag);
            }
        }
    }
    public function setGraphicSize(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
        if(utilInstance.getLuaObject(obj)!=null) {
            var shit:FlxSprite = utilInstance.getLuaObject(obj);
            shit.setGraphicSize(x, y);
            if(updateHitbox) shit.updateHitbox();
            return;
        }

        var killMe:Array<String> = obj.split('.');
        var poop:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            poop = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(poop != null) {
            poop.setGraphicSize(x, y);
            if(updateHitbox) poop.updateHitbox();
            return;
        }
        funkyTrace('Couldnt find object: ' + obj, false, false, FlxColor.RED);
    }
    public function scaleObject(obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
        if(utilInstance.getLuaObject(obj)!=null) {
            var shit:FlxSprite = utilInstance.getLuaObject(obj);
            shit.scale.set(x, y);
            if(updateHitbox) shit.updateHitbox();
            return;
        }

        var killMe:Array<String> = obj.split('.');
        var poop:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            poop = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(poop != null) {
            poop.scale.set(x, y);
            if(updateHitbox) poop.updateHitbox();
            return;
        }
        funkyTrace('Couldnt find object: ' + obj, false, false, FlxColor.RED);
    }
    public function updateHitbox(obj:String) {
        if(utilInstance.getLuaObject(obj)!=null) {
            var shit:FlxSprite = utilInstance.getLuaObject(obj);
            shit.updateHitbox();
            return;
        }

        var poop:FlxSprite = Reflect.getProperty(getInstance(), obj);
        if(poop != null) {
            poop.updateHitbox();
            return;
        }
        funkyTrace('Couldnt find object: ' + obj, false, false, FlxColor.RED);
    }
    public function updateHitboxFromGroup(group:String, index:Int) {
        if(Std.isOfType(Reflect.getProperty(getInstance(), group), FlxTypedGroup)) {
            Reflect.getProperty(getInstance(), group).members[index].updateHitbox();
            return;
        }
        Reflect.getProperty(getInstance(), group)[index].updateHitbox();
    }

    public function isNoteChild(parentID:Int, childID:Int){
        var parent: Note = cast utilInstance.getLuaObject('note${parentID}',false);
        var child: Note = cast utilInstance.getLuaObject('note${childID}',false);
        if(parent!=null && child!=null)
            return parent.tail.contains(child);

        funkyTrace('${parentID} or ${childID} is not a valid note ID', false, false, FlxColor.RED);
        return false;
    }

    public function removeLuaSprite(tag:String, destroy:Bool = true) {
        if(!utilInstance.modchartSprites.exists(tag)) {
            return;
        }

        var pee:ModchartSprite = utilInstance.modchartSprites.get(tag);
        if(destroy) {
            pee.kill();
        }

        if(pee.wasAdded) {
            getInstance().remove(pee, true);
            pee.wasAdded = false;
        }

        if(destroy) {
            pee.destroy();
            utilInstance.modchartSprites.remove(tag);
        }
    }

    public function luaSpriteExists(tag:String) {
        return utilInstance.modchartSprites.exists(tag);
    }
    public function luaTextExists(tag:String) {
        return utilInstance.modchartTexts.exists(tag);
    }
    public function luaSoundExists(tag:String) {
        return utilInstance.modchartSounds.exists(tag);
    }

    public function setHealthBarColors(leftHex:String, rightHex:String) {
        if(!isPlayState) return;
		var left:FlxColor = Std.parseInt(leftHex);
        if(!leftHex.startsWith('0x')) left = Std.parseInt('0xff' + leftHex);
        var right:FlxColor = Std.parseInt(rightHex);
        if(!rightHex.startsWith('0x')) right = Std.parseInt('0xff' + rightHex);

        playInstance.healthBar.createFilledBar(left, right);
        playInstance.healthBar.updateBar();
    }
    public function setTimeBarColors(leftHex:String, rightHex:String) {
        if(!isPlayState) return;
		var left:FlxColor = Std.parseInt(leftHex);
        if(!leftHex.startsWith('0x')) left = Std.parseInt('0xff' + leftHex);
        var right:FlxColor = Std.parseInt(rightHex);
        if(!rightHex.startsWith('0x')) right = Std.parseInt('0xff' + rightHex);

        playInstance.timeBar.createFilledBar(right, left);
        playInstance.timeBar.updateBar();
    }

    public function setObjectCamera(obj:String, camera:String = '') {
        /*if(utilInstance.modchartSprites.exists(obj)) {
            utilInstance.modchartSprites.get(obj).cameras = [cameraFromString(camera)];
            return true;
        }
        else if(utilInstance.modchartTexts.exists(obj)) {
            utilInstance.modchartTexts.get(obj).cameras = [cameraFromString(camera)];
            return true;
        }*/
        var real = utilInstance.getLuaObject(obj);
        if(real!=null){
            real.cameras = [cameraFromString(camera)];
            return true;
        }

        var killMe:Array<String> = obj.split('.');
        var object:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            object = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(object != null) {
            object.cameras = [cameraFromString(camera)];
            return true;
        }
        funkyTrace("Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
        return false;
    }
    public function setBlendMode(obj:String, blend:String = '') {
        var real = utilInstance.getLuaObject(obj);
        if(real!=null) {
            real.blend = blendModeFromString(blend);
            return true;
        }

        var killMe:Array<String> = obj.split('.');
        var spr:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(spr != null) {
            spr.blend = blendModeFromString(blend);
            return true;
        }
        funkyTrace("Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
        return false;
    }
    public function screenCenter(obj:String, pos:String = 'xy') {
        var spr:FlxSprite = utilInstance.getLuaObject(obj);

        if(spr==null){
            var killMe:Array<String> = obj.split('.');
            spr = getObjectDirectly(killMe[0]);
            if(killMe.length > 1) {
                spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
            }
        }

        if(spr != null)
        {
            switch(pos.trim().toLowerCase())
            {
                case 'x':
                    spr.screenCenter(X);
                    return;
                case 'y':
                    spr.screenCenter(Y);
                    return;
                default:
                    spr.screenCenter(XY);
                    return;
            }
        }
        funkyTrace("Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
    }
    public function objectsOverlap(obj1:String, obj2:String) {
        var namesArray:Array<String> = [obj1, obj2];
        var objectsArray:Array<FlxSprite> = [];
        for (i in 0...namesArray.length)
        {
            var real = utilInstance.getLuaObject(namesArray[i]);
            if(real!=null) {
                objectsArray.push(real);
            } else {
                objectsArray.push(Reflect.getProperty(getInstance(), namesArray[i]));
            }
        }

        if(!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]))
        {
            return true;
        }
        return false;
    }
    public function getPixelColor(obj:String, x:Int, y:Int) {
        var killMe:Array<String> = obj.split('.');
        var spr:FlxSprite = getObjectDirectly(killMe[0]);
        if(killMe.length > 1) {
            spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
        }

        if(spr != null)
        {
            if(spr.framePixels != null) spr.framePixels.getPixel32(x, y);
            return spr.pixels.getPixel32(x, y);
        }
        return 0;
    }
    public function getRandomInt(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
        var excludeArray:Array<String> = exclude.split(',');
        var toExclude:Array<Int> = [];
        for (i in 0...excludeArray.length)
        {
            toExclude.push(Std.parseInt(excludeArray[i].trim()));
        }
        return FlxG.random.int(min, max, toExclude);
    }
    public function getRandomFloat(min:Float, max:Float = 1, exclude:String = '') {
        var excludeArray:Array<String> = exclude.split(',');
        var toExclude:Array<Float> = [];
        for (i in 0...excludeArray.length)
        {
            toExclude.push(Std.parseFloat(excludeArray[i].trim()));
        }
        return FlxG.random.float(min, max, toExclude);
    }
    public function getRandomBool(chance:Float = 50) {
        return FlxG.random.bool(chance);
    }
    public function startDialogue(dialogueFile:String, music:String = null) {
        if(!isPlayState) return false;
		var path:String;
        #if MODS_ALLOWED
        path = Paths.modsJson(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
        if(!FileSystem.exists(path))
        #end
            path = Paths.json(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);

        funkyTrace('Trying to load dialogue: ' + path);

        #if MODS_ALLOWED
        if(FileSystem.exists(path))
        #else
        if(Assets.exists(path))
        #end
        {
            var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
            if(shit.dialogue.length > 0) {
                playInstance.startDialogue(shit, music);
                funkyTrace('Successfully loaded dialogue', false, false, FlxColor.GREEN);
                return true;
            } else {
                funkyTrace('Your dialogue file is badly formatted!', false, false, FlxColor.RED);
            }
        } else {
            funkyTrace('Dialogue file not found', false, false, FlxColor.RED);
            if(playInstance.endingSong) {
                playInstance.endSong();
            } else {
                playInstance.startCountdown();
            }
        }
        return false;
    }
    public function startVideo(videoFile:String) {
        #if VIDEOS_ALLOWED
        if(FileSystem.exists(Paths.video(videoFile))) {
            utilInstance.startVideo(videoFile);
            return true;
        } else {
            funkyTrace('Video file not found: ' + videoFile, false, false, FlxColor.RED);
        }
        return false;

        #else
        if(!isPlayState) return true;
		if(utilInstance.endingSong) {
            utilInstance.endSong();
        } else {
            utilInstance.startCountdown();
        }
        return true;
        #end
    }

    public function playMusic(sound:String, volume:Float = 1, loop:Bool = false) {
        FlxG.sound.playMusic(Paths.music(sound), volume, loop);
    }
    public function playSound(sound:String, volume:Float = 1, ?tag:String = null) {
        if(tag != null && tag.length > 0) {
            tag = tag.replace('.', '');
            if(utilInstance.modchartSounds.exists(tag)) {
                utilInstance.modchartSounds.get(tag).stop();
            }
            utilInstance.modchartSounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, function() {
                utilInstance.modchartSounds.remove(tag);
                utilInstance.callOnLuas('onSoundFinished', [tag]);
            }));
            return;
        }
        FlxG.sound.play(Paths.sound(sound), volume);
    }
    public function stopSound(tag:String) {
        if(tag != null && tag.length > 1 && utilInstance.modchartSounds.exists(tag)) {
            utilInstance.modchartSounds.get(tag).stop();
            utilInstance.modchartSounds.remove(tag);
        }
    }
    public function pauseSound(tag:String) {
        if(tag != null && tag.length > 1 && utilInstance.modchartSounds.exists(tag)) {
            utilInstance.modchartSounds.get(tag).pause();
        }
    }
    public function resumeSound(tag:String) {
        if(tag != null && tag.length > 1 && utilInstance.modchartSounds.exists(tag)) {
            utilInstance.modchartSounds.get(tag).play();
        }
    }
    public function soundFadeIn(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
        if(tag == null || tag.length < 1) {
            FlxG.sound.music.fadeIn(duration, fromValue, toValue);
        } else if(utilInstance.modchartSounds.exists(tag)) {
            utilInstance.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
        }

    }
    public function soundFadeOut(tag:String, duration:Float, toValue:Float = 0) {
        if(tag == null || tag.length < 1) {
            FlxG.sound.music.fadeOut(duration, toValue);
        } else if(utilInstance.modchartSounds.exists(tag)) {
            utilInstance.modchartSounds.get(tag).fadeOut(duration, toValue);
        }
    }
    public function soundFadeCancel(tag:String) {
        if(tag == null || tag.length < 1) {
            if(FlxG.sound.music.fadeTween != null) {
                FlxG.sound.music.fadeTween.cancel();
            }
        } else if(utilInstance.modchartSounds.exists(tag)) {
            var theSound:FlxSound = utilInstance.modchartSounds.get(tag);
            if(theSound.fadeTween != null) {
                theSound.fadeTween.cancel();
                utilInstance.modchartSounds.remove(tag);
            }
        }
    }
    public function getSoundVolume(tag:String) {
        if(tag == null || tag.length < 1) {
            if(FlxG.sound.music != null) {
                return FlxG.sound.music.volume;
            }
        } else if(utilInstance.modchartSounds.exists(tag)) {
            return utilInstance.modchartSounds.get(tag).volume;
        }
        return 0;
    }
    public function setSoundVolume(tag:String, value:Float) {
        if(tag == null || tag.length < 1) {
            if(FlxG.sound.music != null) {
                FlxG.sound.music.volume = value;
            }
        } else if(utilInstance.modchartSounds.exists(tag)) {
            utilInstance.modchartSounds.get(tag).volume = value;
        }
    }
    public function getSoundTime(tag:String) {
        if(tag != null && tag.length > 0 && utilInstance.modchartSounds.exists(tag)) {
            return utilInstance.modchartSounds.get(tag).time;
        }
        return 0;
    }
    public function setSoundTime(tag:String, value:Float) {
        if(tag != null && tag.length > 0 && utilInstance.modchartSounds.exists(tag)) {
            var theSound:FlxSound = utilInstance.modchartSounds.get(tag);
            if(theSound != null) {
                var wasResumed:Bool = theSound.playing;
                theSound.pause();
                theSound.time = value;
                if(wasResumed) theSound.play();
            }
        }
    }

    public function debugPrint(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = '') {
        if (text1 == null) text1 = '';
        if (text2 == null) text2 = '';
        if (text3 == null) text3 = '';
        if (text4 == null) text4 = '';
        if (text5 == null) text5 = '';
        funkyTrace('' + text1 + text2 + text3 + text4 + text5, true, false);
    }


    public function changePresence(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
        #if desktop
        DiscordClient.changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
        #end
    }


    // LUA TEXTS
    public function makeLuaText(tag:String, text:String, width:Int, x:Float, y:Float) {
        tag = tag.replace('.', '');
        resetTextTag(tag);
        var leText:ModchartText = new ModchartText(x, y, text, width);
        utilInstance.modchartTexts.set(tag, leText);
    }

    public function setTextString(tag:String, text:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            obj.text = text;
        }
    }
    public function setTextSize(tag:String, size:Int) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            obj.size = size;
        }
    }
    public function setTextWidth(tag:String, width:Float) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            obj.fieldWidth = width;
        }
    }
    public function setTextBorder(tag:String, size:Int, color:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            var colorNum:Int = Std.parseInt(color);
            if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

            obj.borderSize = size;
            obj.borderColor = colorNum;
        }
    }
    public function setTextColor(tag:String, color:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            var colorNum:Int = Std.parseInt(color);
            if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

            obj.color = colorNum;
        }
    }
    public function setTextFont(tag:String, newFont:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            obj.font = Paths.font(newFont);
        }
    }
    public function setTextItalic(tag:String, italic:Bool) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            obj.italic = italic;
        }
    }
    public function setTextAlignment(tag:String, alignment:String = 'left') {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            obj.alignment = LEFT;
            switch(alignment.trim().toLowerCase())
            {
                case 'right':
                    obj.alignment = RIGHT;
                case 'center':
                    obj.alignment = CENTER;
            }
        }
    }

    public function getTextString(tag:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null && obj.text != null)
        {
            return obj.text;
        }
        return null;
    }
    public function getTextSize(tag:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            return obj.size;
        }
        return -1;
    }
    public function getTextFont(tag:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            return obj.font;
        }
        return null;
    }
    public function getTextWidth(tag:String) {
        var obj:FlxText = getTextObject(tag);
        if(obj != null)
        {
            return obj.fieldWidth;
        }
        return 0;
    }

    public function addLuaText(tag:String) {
        if(utilInstance.modchartTexts.exists(tag)) {
            var shit:ModchartText = utilInstance.modchartTexts.get(tag);
            if(!shit.wasAdded) {
                getInstance().add(shit);
                shit.wasAdded = true;
                //trace('added a thing: ' + tag);
            }
        }
    }
    public function removeLuaText(tag:String, destroy:Bool = true) {
        if(!utilInstance.modchartTexts.exists(tag)) {
            return;
        }

        var pee:ModchartText = utilInstance.modchartTexts.get(tag);
        if(destroy) {
            pee.kill();
        }

        if(pee.wasAdded) {
            getInstance().remove(pee, true);
            pee.wasAdded = false;
        }

        if(destroy) {
            pee.destroy();
            utilInstance.modchartTexts.remove(tag);
        }
    }

    public function initSaveData(name:String, ?folder:String = 'psychenginemods') {
        if(!utilInstance.modchartSaves.exists(name))
        {
            var save:FlxSave = new FlxSave();
            save.bind(name, folder);
            utilInstance.modchartSaves.set(name, save);
            return;
        }
        funkyTrace('Save file already initialized: ' + name);
    }
    public function flushSaveData(name:String) {
        if(utilInstance.modchartSaves.exists(name))
        {
            utilInstance.modchartSaves.get(name).flush();
            return;
        }
        funkyTrace('Save file not initialized: ' + name, false, false, FlxColor.RED);
    }
    public function getDataFromSave(name:String, field:String, ?defaultValue:Dynamic = null) {
        if(utilInstance.modchartSaves.exists(name))
        {
            var retVal:Dynamic = Reflect.field(utilInstance.modchartSaves.get(name).data, field);
            return retVal;
        }
        funkyTrace('Save file not initialized: ' + name, false, false, FlxColor.RED);
        return defaultValue;
    }
    public function setDataFromSave(name:String, field:String, value:Dynamic) {
        if(utilInstance.modchartSaves.exists(name))
        {
            Reflect.setField(utilInstance.modchartSaves.get(name).data, field, value);
            return;
        }
        funkyTrace('Save file not initialized: ' + name, false, false, FlxColor.RED);
    }

    public function checkFileExists(filename:String, ?absolute:Bool = false) {
        #if MODS_ALLOWED
        if(absolute)
        {
            return FileSystem.exists(filename);
        }

        var path:String = Paths.modFolders(filename);
        if(FileSystem.exists(path))
        {
            return true;
        }
        return FileSystem.exists(Paths.getPath('assets/$filename', TEXT));
        #else
        if(absolute)
        {
            return Assets.exists(filename);
        }
        return Assets.exists(Paths.getPath('assets/$filename', TEXT));
        #end
    }
    public function saveFile(path:String, content:String, ?absolute:Bool = false)
    {
        try {
            if(!absolute)
                File.saveContent(Paths.mods(path), content);
            else
                File.saveContent(path, content);

            return true;
        } catch (e:Dynamic) {
            funkyTrace("Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
        }
        return false;
    }
    public function deleteFile(path:String, ?ignoreModFolders:Bool = false)
    {
        try {
            #if MODS_ALLOWED
            if(!ignoreModFolders)
            {
                var lePath:String = Paths.modFolders(path);
                if(FileSystem.exists(lePath))
                {
                    FileSystem.deleteFile(lePath);
                    return true;
                }
            }
            #end

            var lePath:String = Paths.getPath(path, TEXT);
            if(Assets.exists(lePath))
            {
                FileSystem.deleteFile(lePath);
                return true;
            }
        } catch (e:Dynamic) {
            funkyTrace("Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
        }
        return false;
    }
    public function getTextFromFile(path:String, ?ignoreModFolders:Bool = false) {
        return Paths.getTextFromFile(path, ignoreModFolders);
    }

    // DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
    public function objectPlayAnimation(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0) {
        funkyTrace("objectPlayAnimation is deprecated! Use playAnim instead", false, true);
        if(utilInstance.getLuaObject(obj,false) != null) {
            utilInstance.getLuaObject(obj,false).animation.play(name, forced, false, startFrame);
            return true;
        }

        var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
        if(spr != null) {
            spr.animation.play(name, forced, false, startFrame);
            return true;
        }
        return false;
    }
    public function characterPlayAnim(character:String, anim:String, ?forced:Bool = false) {
        if(!isPlayState) return;
		funkyTrace("characterPlayAnim is deprecated! Use playAnim instead", false, true);
        switch(character.toLowerCase()) {
            case 'dad':
                if(playInstance.dad.animOffsets.exists(anim))
                    playInstance.dad.playAnim(anim, forced);
            case 'gf' | 'girlfriend':
                if(playInstance.gf != null && playInstance.gf.animOffsets.exists(anim))
                    playInstance.gf.playAnim(anim, forced);
            default:
                if(playInstance.boyfriend.animOffsets.exists(anim))
                    playInstance.boyfriend.playAnim(anim, forced);
        }
    }
    public function luaSpriteMakeGraphic(tag:String, width:Int, height:Int, color:String) {
        funkyTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);
        if(utilInstance.modchartSprites.exists(tag)) {
            var colorNum:Int = Std.parseInt(color);
            if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

            utilInstance.modchartSprites.get(tag).makeGraphic(width, height, colorNum);
        }
    }
    public function luaSpriteAddAnimationByPrefix(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
        funkyTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);
        if(utilInstance.modchartSprites.exists(tag)) {
            var cock:ModchartSprite = utilInstance.modchartSprites.get(tag);
            cock.animation.addByPrefix(name, prefix, framerate, loop);
            if(cock.animation.curAnim == null) {
                cock.animation.play(name, true);
            }
        }
    }
    public function luaSpriteAddAnimationByIndices(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
        funkyTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);
        if(utilInstance.modchartSprites.exists(tag)) {
            var strIndices:Array<String> = indices.trim().split(',');
            var die:Array<Int> = [];
            for (i in 0...strIndices.length) {
                die.push(Std.parseInt(strIndices[i]));
            }
            var pussy:ModchartSprite = utilInstance.modchartSprites.get(tag);
            pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
            if(pussy.animation.curAnim == null) {
                pussy.animation.play(name, true);
            }
        }
    }
    public function luaSpritePlayAnimation(tag:String, name:String, forced:Bool = false) {
        funkyTrace("luaSpritePlayAnimation is deprecated! Use playAnim instead", false, true);
        if(utilInstance.modchartSprites.exists(tag)) {
            utilInstance.modchartSprites.get(tag).animation.play(name, forced);
        }
    }
    public function setLuaSpriteCamera(tag:String, camera:String = '') {
        funkyTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);
        if(utilInstance.modchartSprites.exists(tag)) {
            utilInstance.modchartSprites.get(tag).cameras = [cameraFromString(camera)];
            return true;
        }
        funkyTrace("Lua sprite with tag: " + tag + " doesn't exist!");
        return false;
    }
    public function setLuaSpriteScrollFactor(tag:String, scrollX:Float, scrollY:Float) {
        funkyTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
        if(utilInstance.modchartSprites.exists(tag)) {
            utilInstance.modchartSprites.get(tag).scrollFactor.set(scrollX, scrollY);
            return true;
        }
        return false;
    }
    public function scaleLuaSprite(tag:String, x:Float, y:Float) {
        funkyTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, true);
        if(utilInstance.modchartSprites.exists(tag)) {
            var shit:ModchartSprite = utilInstance.modchartSprites.get(tag);
            shit.scale.set(x, y);
            shit.updateHitbox();
            return true;
        }
        return false;
    }
    public function getPropertyLuaSprite(tag:String, variable:String) {
        funkyTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);
        if(utilInstance.modchartSprites.exists(tag)) {
            var killMe:Array<String> = variable.split('.');
            if(killMe.length > 1) {
                var coverMeInPiss:Dynamic = Reflect.getProperty(utilInstance.modchartSprites.get(tag), killMe[0]);
                for (i in 1...killMe.length-1) {
                    coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
                }
                return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
            }
            return Reflect.getProperty(utilInstance.modchartSprites.get(tag), variable);
        }
        return null;
    }
    public function setPropertyLuaSprite(tag:String, variable:String, value:Dynamic) {
        funkyTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);
        if(utilInstance.modchartSprites.exists(tag)) {
            var killMe:Array<String> = variable.split('.');
            if(killMe.length > 1) {
                var coverMeInPiss:Dynamic = Reflect.getProperty(utilInstance.modchartSprites.get(tag), killMe[0]);
                for (i in 1...killMe.length-1) {
                    coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
                }
                Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
                return true;
            }
            Reflect.setProperty(utilInstance.modchartSprites.get(tag), variable, value);
            return true;
        }
        funkyTrace("Lua sprite with tag: " + tag + " doesn't exist!");
        return false;
    }
    public function musicFadeIn(duration:Float, fromValue:Float = 0, toValue:Float = 1) {
        FlxG.sound.music.fadeIn(duration, fromValue, toValue);
        funkyTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);

    }
    public function musicFadeOut(duration:Float, toValue:Float = 0) {
        FlxG.sound.music.fadeOut(duration, toValue);
        funkyTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
    }

    // Other stuff
    public function stringStartsWith(str:String, start:String) {
        return str.startsWith(start);
    }
    public function stringEndsWith(str:String, end:String) {
        return str.endsWith(end);
    }
    public function stringSplit(str:String, split:String) {
        return str.split(split);
    }
    public function stringTrim(str:String) {
        return str.trim();
    }

    public function directoryFileList(folder:String) {
        var list:Array<String> = [];
        #if sys
        if(FileSystem.exists(folder)) {
            for (folder in FileSystem.readDirectory(folder)) {
                if (!list.contains(folder)) {
                    list.push(folder);
                }
            }
        }
        #end
        return list;
    }
    //}
}