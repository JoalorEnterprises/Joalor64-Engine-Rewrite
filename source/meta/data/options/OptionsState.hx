package meta.data.options;

#if desktop
import meta.data.dependency.Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxColor;
import lime.utils.Assets;
import lime.app.Application;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import flixel.FlxCamera;
import flixel.FlxObject;
import meta.*;
import meta.data.*;
import meta.data.alphabet.*;
import meta.data.options.*;
import meta.state.*;
import meta.state.error.*;
import meta.substate.*;

using StringTools;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		#if (MODS_ALLOWED && FUTURE_POLYMOD) 'Mod Options', #end
		'Note Colors', 
		'Controls', 
		'Visuals and Graphics',
		'Gameplay Preferences',
		'Adjust Delay and Combo', 
		'Miscellaneous'
	];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;

	function openSelectedSubstate(label:String) {
		switch(label) {
			#if (MODS_ALLOWED && FUTURE_POLYMOD)
			case 'Mod Options':
			    	if (Paths.optionsExist())
					FlxG.switchState(new ModOptionSelectState());
				else
					FlxG.switchState(new OopsState());
			#end
			case 'Note Colors':
				if(ClientPrefs.arrowMode == 'RGB')
					openSubState(new NotesRGBSubState());
				else
					openSubState(new NotesHSVSubState());
			case 'Controls':
				openSubState(new ControlsSubState());
			case 'Visuals and Graphics':
				openSubState(new VisualsSubState());
			case 'Gameplay Preferences':
				openSubState(new GameplaySubState());
			case 'Adjust Delay and Combo':
				LoadingState.loadAndSwitchState(new NoteOffsetState());
			case 'Miscellaneous':
				openSubState(new MiscSubState());
		}
	}

	var bg:FlxSprite;
	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var camMain:FlxCamera;
	var camSub:FlxCamera;

	var yScroll:Float;

	override function create() {
		#if desktop
		DiscordClient.changePresence("Options Menu", null);
		#end

		Application.current.window.title = Application.current.meta.get('name');

		camMain = new FlxCamera();
		camSub = new FlxCamera();
		camSub.bgColor.alpha = 0;

		FlxG.cameras.reset(camMain);
		FlxG.cameras.add(camSub, false);

		FlxG.cameras.setDefaultDrawTarget(camMain, true);
		CustomFadeTransition.nextCamera = camSub;

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, null, 1);

		yScroll = Math.max(0.25 - (0.05 * (options.length - 4)), 0.1);
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.color = 0xFFea71fd;
		bg.scale.set(1.07, 1.07);
		bg.updateHitbox();
		bg.scrollFactor.set(0, yScroll / 3);
		bg.screenCenter();
		bg.y += 5;
		add(bg);
		
		initOptions();

		selectorLeft = new Alphabet(0, 0, '>', true);
		selectorLeft.scrollFactor.set(0, yScroll);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		selectorRight.scrollFactor.set(0, yScroll);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	function initOptions() {
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			optionText.scrollFactor.set(0, yScroll);
			grpOptions.add(optionText);
		}
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		var lerpVal:Float = CoolUtil.clamp(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		var mult:Float = FlxMath.lerp(1.07, bg.scale.x, CoolUtil.clamp(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();
		bg.offset.set();
		
		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (PauseSubState.fromPlayState) {
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
			} else {
				if (ClientPrefs.simpleMain)
					MusicBeatState.switchState(new SimpleMainMenuState());
				else
					MusicBeatState.switchState(new MainMenuState());
			}
		}

		if (controls.ACCEPT) {
			openSelectedSubstate(options[curSelected]);
		}
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}