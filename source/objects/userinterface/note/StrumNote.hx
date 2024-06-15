package objects.userinterface.note;

import flixel.graphics.frames.FlxAtlasFrames;
import objects.shaders.*;
import objects.userinterface.note.*;

class StrumNote extends FlxSprite
{
	private var colorMask:ColorMask;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	
	private var player:Int;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int) {
		animation = new PsychAnimationController(this);
		
		colorMask = new ColorMask();
		noteData = leData;
		this.player = player;
		this.noteData = leData;
		super(x, y);

		var arr:Array<FlxColor> = ClientPrefs.arrowRGBExtra[EK.gfxIndex[PlayState.mania][leData]];
		if(PlayState.isPixelStage) arr = ClientPrefs.arrowRGBPixelExtra[EK.gfxIndex[PlayState.mania][leData]];

		var skin:String = 'NOTE_assets';
		if(PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		shader = colorMask.shader;
		texture = skin; //Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(PlayState.isPixelStage) {
			loadGraphic(Paths.image('pixelUI/$texture'));
			width /= 9;
			height /= 5;
			loadGraphic(Paths.image('pixelUI/$texture'), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom * EK.scalesPixel[PlayState.mania]));
	
			animation.add('purple', [9]);
			animation.add('blue', [10]);
			animation.add('green', [11]);
			animation.add('red', [12]);
			animation.add('white', [13]);
			animation.add('yellow', [14]);
			animation.add('violet', [15]);
			animation.add('black', [16]);
			animation.add('dark', [17]);

			var dataNum:Int = EK.gfxIndex[PlayState.mania][noteData];
			animation.add('static', [dataNum]);
			animation.add('pressed', [9 + dataNum, 18 + dataNum], 12, false);
			animation.add('confirm', [27 + dataNum, 36 + dataNum], 12, false);
		} else {
			frames = Paths.getSparrowAtlas(texture);
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('red', 'arrowRIGHT');
			animation.addByPrefix('white', 'arrowSPACE');
			animation.addByPrefix('yellow', 'arrowLEFT');
			animation.addByPrefix('violet', 'arrowDOWN');
			animation.addByPrefix('black', 'arrowUP');
			animation.addByPrefix('dark', 'arrowRIGHT');

			antialiasing = ClientPrefs.globalAntialiasing;
			setGraphicSize(Std.int(width * EK.scales[PlayState.mania]));

			var pressName:String = EK.colArray[EK.gfxIndex[PlayState.mania][noteData]];
			var pressNameAlt:String = EK.pressArrayAlt[EK.gfxIndex[PlayState.mania][noteData]];
			animation.addByPrefix('static', 'arrow' + EK.gfxDir[EK.gfxHud[PlayState.mania][noteData]]);
			attemptToAddAnimationByPrefix('pressed', pressNameAlt + ' press', 24, false);
			attemptToAddAnimationByPrefix('confirm', pressNameAlt + ' confirm', 24, false);
			animation.addByPrefix('pressed', pressName + ' press', 24, false);
			animation.addByPrefix('confirm', pressName + ' confirm', 24, false);
		}
		updateHitbox();

		if(lastAnim != null) playAnim(lastAnim, true);
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
			centerOrigin();
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		if(animation.curAnim == null || animation.curAnim.name == 'static') {
			// RGB
			colorMask.rCol = 0xFF87A3AD;
			colorMask.gCol = FlxColor.BLACK;
		} else {
			if (noteData > -1 && noteData < ClientPrefs.arrowRGB.length)
			{
				colorMask.rCol = FlxColor.fromRGB(ClientPrefs.arrowRGB[noteData][0], ClientPrefs.arrowRGB[noteData][1], ClientPrefs.arrowRGB[noteData][2]);
				colorMask.gCol = colorMask.rCol.getDarkened(0.6);

				if (animation.curAnim.name == 'pressed')
				{
					var color:FlxColor = colorMask.rCol;
					colorMask.rCol = FlxColor.fromHSL(color.hue, color.saturation * 0.5, color.lightness * 1.2);
					colorMask.gCol = 0xFF201E31;
				}
			}

			if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
				centerOrigin();
			}
		}
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true) {
		var animFrames:Array<flixel.graphics.frames.FlxFrame> = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}
}