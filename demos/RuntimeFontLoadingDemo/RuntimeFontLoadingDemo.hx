import flash.events.Event;
import flash.system.LoaderContext;
import flash.system.ApplicationDomain;
import flash.text.Font;

class RuntimeFontLoadingDemo {
   public function new() {
      //
      // The swf is loaded from a binary embedded object now, but could hve been
      // loaded from an external source as well.
      //
      var external_swf: flash.utils.ByteArray = Type.createInstance(Type.resolveClass("resources.classes.FontContainerSwf"), []);

      var ldr = new flash.display.Loader();
      ldr.loadBytes(
         external_swf,
         new LoaderContext(false, new ApplicationDomain())
      );
      ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
   }

   function onComplete(e: Event) {
      //
      // Rerieve and register font by class name
      //
      var fontClass: Class<Font> = e.target.applicationDomain.getDefinition("resources.classes.CFont");
      Font.registerFont(fontClass);

      // Now we can use the font by its "name" attribute
      var tf = new flash.text.TextField();
      
      tf.embedFonts = true;
      tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
      tf.multiline = true;
      tf.selectable = false;
      tf.width = 400;
      
      var t_fmt = new flash.text.TextFormat("CourierFont", 18);
      t_fmt.align = flash.text.TextFormatAlign.LEFT;
      tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
      
      tf.defaultTextFormat = t_fmt;

      tf.text = "This text is displayed with the imported font!\nAnd this is the second line!";
      
      flash.Lib.current.addChild(tf);
      tf.x = 10;
      tf.y = 10;
   }
   
   public static function main() {
      new RuntimeFontLoadingDemo();
   }
}

