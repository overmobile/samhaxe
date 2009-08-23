class FontDemo {
   public function new() {
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
      new FontDemo();
   }
}

