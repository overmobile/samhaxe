class AnimationDemo {
   public function new() {
      var animation: flash.display.MovieClip = Type.createInstance(Type.resolveClass("resources.classes.SwfAnimation"), []);

      flash.Lib.current.addChild(animation);
      animation.x = 150;
      animation.y = 150;
   }
   
   public static function main() {
      new AnimationDemo();
   }
}
