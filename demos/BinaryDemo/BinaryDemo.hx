class BinaryDemo {
   public function new() {
      var text_file: flash.utils.ByteArray = Type.createInstance(Type.resolveClass("resources.classes.TextFile"), []);
      text_file.uncompress();

      trace(text_file.toString());
   }
   
   public static function main() {
      new BinaryDemo();
   }
}
