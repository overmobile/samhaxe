class ImageDemo {
   public function new() {
      var mantis: flash.display.Bitmap = Type.createInstance(Type.resolveClass("resources.classes.MantisImage"), []);
      var logo: flash.display.Bitmap = Type.createInstance(Type.resolveClass("resources.classes.MlabsLogo"), []);

      flash.Lib.current.addChild(mantis);
      flash.Lib.current.addChild(logo);
      logo.x = mantis.width - logo.width;
      logo.y = mantis.height - logo.height;
   }
   
   public static function main() {
      new ImageDemo();
   }
}
