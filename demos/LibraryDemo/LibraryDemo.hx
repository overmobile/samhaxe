class LibraryDemo {
   public function new() {
      var library: Dynamic = Type.createInstance(Type.resolveClass("ExtLibrary"), []);

      var circle: flash.display.Shape = library.getCircle(10.0);
      flash.Lib.current.addChild(circle);
      circle.x = 20.0;
      circle.y = 20.0;
      
      var box: flash.display.Shape = library.getBox(20.0, 30.0);
      flash.Lib.current.addChild(box);
      box.x = 100.0;
      box.y = 100.0;
   }
   
   public static function main() {
      new LibraryDemo();
   }
}
