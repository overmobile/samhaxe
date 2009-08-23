import flash.Lib;

class AllDemo {
   var fully_loaded: Bool;

   var progress : flash.display.Shape;
   
   function new() {
      var masked_mantis: flash.display.Bitmap = Type.createInstance(Type.resolveClass("resources.classes.MaskedMantis"), []);
      Lib.current.addChild(masked_mantis);

      var logo: flash.display.Bitmap = Type.createInstance(Type.resolveClass("resources.classes.Logo"), []);
      logo.x = 640 - logo.width;
      logo.y = 480 - logo.height;
      Lib.current.addChild(logo);
      
      var tick_snd: flash.media.Sound = Type.createInstance(Type.resolveClass("resources.classes.TickSnd"), []);
      tick_snd.play();
      
      var anim: flash.display.MovieClip = Type.createInstance(Type.resolveClass("resources.classes.Animation"), []);
      anim.x = 200;
      anim.y = 200;
      Lib.current.addChild(anim);


      var text_file: flash.utils.ByteArray = Type.createInstance(Type.resolveClass("resources.classes.TextFile"), []);

      var tf = new flash.text.TextField();
      
      tf.embedFonts = true;
      tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
      tf.multiline = true;
      tf.selectable = false;
      tf.width = 200;
      
      var t_fmt = new flash.text.TextFormat("MainFont", 18);
      t_fmt.align = flash.text.TextFormatAlign.LEFT;
      tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
      
      tf.defaultTextFormat = t_fmt;

      tf.text = text_file.toString();
      Lib.current.addChild(tf);
      tf.x = 10;
      tf.y = 150;
      
      var progressBg = new flash.display.Shape();
      var g = progressBg.graphics;
      g.beginFill(0x002288);
      g.drawRect(-2,-2,104, 14);
      Lib.current.addChild(progressBg);

      progress = new flash.display.Shape();
      g = progress.graphics;
      g.beginFill(0x00ff88);
      g.drawRect(0,0,100, 10);
      Lib.current.addChild(progress);
      
      progressBg.x = progress.x = 50;
      progressBg.y = progress.y = 30;
      progress.scaleX = 0;

      fully_loaded = false;
      Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, onEnterFrame);
   }

   function onEnterFrame(e: flash.events.Event) {
      var totalBytes = flash.Lib.current.loaderInfo.bytesTotal;
      var actBytes = flash.Lib.current.loaderInfo.bytesLoaded;
      
      if (!fully_loaded && actBytes <= totalBytes) {
         progress.scaleX = 1.0 * actBytes / totalBytes;
      }

      if (!fully_loaded && actBytes == totalBytes) {
         fully_loaded = true;

         var explode_snd: flash.media.Sound = Type.createInstance(Type.resolveClass("resources.classes.ExplodeSnd"), []);
         explode_snd.play();
         
         var bg_music: flash.media.Sound = Type.createInstance(Type.resolveClass("resources.classes.BgMusic"), []);
         bg_music.play();
      }
   }
   
   public static function main() {
      new AllDemo();
   }
}
