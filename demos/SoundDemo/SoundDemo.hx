class SoundDemo {
   public function new() {
      var explode: flash.media.Sound = Type.createInstance(Type.resolveClass("resources.classes.ExplodeSound"), []);
      explode.play();
   }
   
   public static function main() {
      new SoundDemo();
   }
}
