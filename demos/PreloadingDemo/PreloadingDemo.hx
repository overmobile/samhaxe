class PreloadingDemo {

   var progress: flash.display.Shape;
   var fully_loaded: Bool;
   
   public function new() {
      var progressBg = new flash.display.Shape();
      var g = progressBg.graphics;
      g.beginFill(0x002288);
      g.drawRect(-2, -2, 104, 14);
      flash.Lib.current.addChild(progressBg);
      progressBg.x = 10;
      progressBg.y = 10;

      progress = new flash.display.Shape();
      g = progress.graphics;
      g.beginFill(0x00ff88);
      g.drawRect(0, 0, 100, 10);
      flash.Lib.current.addChild(progress);
      progress.x = 10;
      progress.y = 10;
      
      fully_loaded = false;
      flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, onEnterFrame);
   }
   
   function onEnterFrame(e: flash.events.Event) {
      var totalBytes = flash.Lib.current.loaderInfo.bytesTotal;
      var actBytes = flash.Lib.current.loaderInfo.bytesLoaded;
      
      if (!fully_loaded && actBytes <= totalBytes) {
         progress.scaleX = 1.0 * actBytes / totalBytes;
      }

      if (!fully_loaded && actBytes == totalBytes) {
         fully_loaded = true;
         
         var music: flash.media.Sound = Type.createInstance(Type.resolveClass("resources.classes.Music"), []);
         music.play();
      }
   }
   
   public static function main() {
      new PreloadingDemo();
   }
}
