class ClassStubDemo {
   public function new() {
      var mantis: flash.display.Bitmap = new resources.classes.MantisImage();

      flash.Lib.current.addChild(mantis);
   }
   
   public static function main() {
      new ClassStubDemo();
   }
}
