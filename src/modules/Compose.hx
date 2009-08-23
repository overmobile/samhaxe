/*
   Title: Compose.hx
      Compose tutorial import module for demonstrating the use of other import modules from a module.

   Section: compose
      Imports assets from different sources by invoking other modules.

   Mandatory attributes:
      None

   Optional attributes:
      None

   Superclass:
      No AS3 class stub is generated.

   Example:
      Assuming that Compose import module is assigned to namespace _comp_, Sound import module to _snd_
      and Image import module to _img_ the following snippet imports _tick.wav_ and _logo.png_
      by passing them to other modules:
      (code)
      <comp:compose>
         <snd:sound import="tick.wav" class="TickSound"/>
         <img:image import="logo.png" class="LogoImage"/>
      </comp:compose>
      (end)
*/
import haxe.xml.Check;
import format.swf.Data;
import SamHaXeModule;
import ModuleService;

class Compose {
   static var interface_versions = ["1.0.0", "1.1.0"];
   
   static var description_compose: String = "Compose module // (c) 2009 Mindless Labs";
   
   var moduleService_1_0 : ModuleService_1_0;

   // For test purposes only.
   // Because we don't really have ModuleService_1_1
   // just use ModuleService_1_0 type now.
   var moduleService_1_1 : ModuleService_1_0;

   public function new() {
   }
   
   //
   // Interface 1.0
   // 

   public function check_compose_1_0(elem: NsFastXml) {
      if (elem.lname != "compose")
         throw "Only the 'compose' tag is supported!";
   }
   
   public function import_compose_1_0(elem: NsFastXml, options: Hash<String>): Array<SWFTag> {
      var tags = new Array<SWFTag>();

      for (e in elem.elements) {
         for (tag in moduleService_1_0.runImport(e))
            tags.push(tag);
      }
     
      return tags;
   }
   
   public function help_compose_1_0(): String {
      return
'Available XML tags:
  <compose>: Imports assets from different sources by invoking other modules.

  Mandatory attributes:
    None

  Optional attributes:
    None

  Superclass:
    No AS3 class stub is generated.

  Example:
    Assuming that Compose import module is assigned to namespace comp, Sound import module to snd
    and Image import module to img the following snippet imports tick.wav and logo.png
    by passing them to other modules:
      
      <comp:compose>
        <snd:sound import="tick.wav" class="TickSound"/>
        <img:image import="logo.png" class="LogoImage"/>
      </comp:compose>';
   }

   //
   // Interface 1.1
   //

   public function check_compose_1_1(elem: NsFastXml) {
      if (elem.lname != "alfa_compose")
         throw "Only the 'alfa_compose' tag is supported!";
   }
   
   public function import_compose_1_1(elem: NsFastXml, options: Hash<String>): Array<SWFTag> {
      var tags = new Array<SWFTag>();

      for (e in elem.elements) {
         trace("this is still in alfa");
         for (tag in moduleService_1_1.runImport(e))
            tags.push(tag);
      }
     
      return tags;
   }
   
   public function help_compose_1_1(): String {
      return
'Available XML tags:
  <compose_alfa>: Imports assets from different sources by invoking other modules.

  Mandatory attributes:
    None

  Optional attributes:
    None

  Superclass:
    No AS3 class stub is generated.

  Example:
    Assuming that Compose import module is assigned to namespace comp, Sound import module to snd
    and Image import module to img the following snippet imports tick.wav and logo.png
    by passing them to other modules:
      
      <comp:compose_alfa>
        <snd:sound import="tick.wav" class="TickSound"/>
        <img:image import="logo.png" class="LogoImage"/>
      </comp:compose_alfa>';
   }

   public static function initModule(): Bool {
      return true;
   }
   
   public static function initInterface(version: String, moduleService : Dynamic): Void {
      
      var lm = neko.vm.Module.local();
      switch(version) {
         case "1.1.0":
            var module = new Compose();
            module.moduleService_1_1 = cast moduleService;

            lm.setExport(SamHaXeModule.IMPORT_FUN_1_0, module.import_compose_1_1);
            lm.setExport(SamHaXeModule.CHECK_FUN_1_0,  module.check_compose_1_1);
            lm.setExport(SamHaXeModule.HELP_FUN_1_0,   module.help_compose_1_1);

         case "1.0.0":
            var module = new Compose();
            module.moduleService_1_0 = cast moduleService;

            lm.setExport(SamHaXeModule.IMPORT_FUN_1_0, module.import_compose_1_0);
            lm.setExport(SamHaXeModule.CHECK_FUN_1_0,  module.check_compose_1_0);
            lm.setExport(SamHaXeModule.HELP_FUN_1_0,   module.help_compose_1_0);

         default:
            throw "Unsupported interface version (" + version + ") requested!";
      }
   }

   public static function main() {
      var lm = neko.vm.Module.local();
      
      lm.setExport(SamHaXeModule.INTERFACES,     interface_versions);
      lm.setExport(SamHaXeModule.DESCRIPTION,    description_compose);
      lm.setExport(SamHaXeModule.INIT_MODULE,    initModule);
      lm.setExport(SamHaXeModule.INIT_INTERFACE, initInterface);
   }
}
