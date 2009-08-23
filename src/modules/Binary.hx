/*
   Title: Binary.hx
      Binary import module for importing arbitrary data with optional zlib compression.

   Section: binary
      Imports arbitrary data as DefineBinaryData swf tag.

   Mandatory attributes:
      import - Path to the file to be imported.
      class - Class name assigned to imported data.

   Optional attributes:
      genclass - (false, symbolOnly, _symbolAndClass_) Controls the generation of symbols and AS3 class stubs.
         Available values are:
            *false* (don't generate neither symbol nor AS3 class stub),
            *symbolOnly* (generate only symbol),
            *symbolAndClass* (generate symbol and AS3 class stub)

      compress - (_false_, true) Controls the compression of imported data.

   Superclass:
      flash.utils.ByteArray - The superclass of AS3 class stub.

   Example 1:
      Assuming that Binary import module is assigned to namespace _bin_ the following snippet imports
      and then compresses _/data/list.txt_, exports it with symbolclass name
      _resources.NameList_ and generates a corresponding AS3 class stub (default behavior):
      
   >  <bin:binary import="/data/list.txt" class="resources.NameList" compress="true"/>

   Example 2:
      Manual creation of class stub. First import the file with _genclass_ set to _symbolOnly_
   >  <bin:binary import="/data/list.txt" class="resources.NameList" genclass="symbolOnly" compress="true"/>
      then define the class stub in haXe:
      (code)
      package resources;

      class NameList extends flash.utils.ByteArray {
         public function new() {
            super();
         }
      }
      (end)

*/
import haxe.xml.Check;

import format.swf.Constants;
import format.swf.Data;

import SamHaXeModule;
import ModuleService;

class Binary {
   static var interface_versions = ["1.0.0"];

   static var description_binary: String = "Binary import module // (c) 2009 Mindless Labs";
   
   static var superclass: String = "flash.utils.ByteArray";
   
   var moduleService_1_0 : ModuleService_1_0;

   public function new () {
   }
   
   public function check_binary_1_0(binary: NsFastXml): Void {
      var ns = binary.ns + ":";

      var bin_rule = RNode(ns + "binary", [
         Att("import"),
         Att("class"),
         // Specifying a default value makes attributes optional!
         Att("genclass",
            FEnum([
               SamHaXeModule.GENCLASS_FALSE, 
               SamHaXeModule.GENCLASS_SYMBOL_ONLY, 
               SamHaXeModule.GENCLASS_SYMBOL_AND_CLASS
            ]), 
            SamHaXeModule.GENCLASS_SYMBOL_AND_CLASS
         ),
         Att("compress", FBool, "false"),
      ]);
 
      haxe.xml.Check.checkNode(binary.x, bin_rule);
   }

   public function import_binary_1_0(binary: NsFastXml, options: Hash<String>): Array<SWFTag> {
      if(moduleService_1_0.getFlashVersion() < 9)
         throw "Importing binary data requires flash version 9 or higher!";

      var file_name = binary.x.get("import");
      var f : haxe.io.Input;
      try {
         f = neko.io.File.read(file_name, true);
      }
      catch (e : Dynamic) {
         throw "File '" + file_name + "' not found!";
      }
      
      var binary_data = f.readAll();
      
      var should_gen_class = !binary.has.genclass || binary.att.genclass == SamHaXeModule.GENCLASS_SYMBOL_AND_CLASS;
      var should_store_symbol = should_gen_class || binary.att.genclass == SamHaXeModule.GENCLASS_SYMBOL_ONLY;

      var compress = binary.has.compress && binary.att.compress.toLowerCase() == "true";
      var package_name = moduleService_1_0.getVariableRegistry().getVariable("package");
      var class_name = (if(package_name.length > 0) package_name + "." else "") + binary.x.get("class");
      var as3Reg = moduleService_1_0.getAS3Registry();
      var symReg = moduleService_1_0.getSymbolRegistry();

      var cid: Int;
      var hashIdRes = Helpers.getIdForHashSymbolWarn(
         getBinaryHashBase(
            // Use uncompressed data for hashing!
            binary_data
         ),
         TagId.DefineBinaryData,
         moduleService_1_0.getIdRegistry(),
         symReg,
         class_name,
         should_store_symbol
      );
      
      switch (hashIdRes) {
         case HISWR_SkipOk:
            return [];

         case HISWR_DataFound(id):
            if (should_gen_class)
               Helpers.generateClass(as3Reg, class_name, superclass);
             return [];

         case HISWR_New(id):
            if (should_gen_class)
               Helpers.generateClass(as3Reg, class_name, superclass);
            
            cid = id;
            // Continue import
         
         case HISWR_NewOnlyData(id):
            cid = id;
            // Continue import
      }
      
      moduleService_1_0.getDependencyRegistry().addFilePath(file_name);

      return [TBinaryData(cid, if(compress) format.tools.Deflate.run(binary_data) else binary_data)];
   }

   public function help_binary_1_0(): String {
      return
'Available XML tags:
  <binary>: Imports arbitrary data as DefineBinaryData swf tag.

  Mandatory attributes:
    import - Path to the file to be imported.
    class  - Class name assigned to imported data.

  Optional attributes:
    genclass - Controls the generation of symbols and AS3 class stubs.
      false          - Do not generate neither symbol nor AS3 class stub.
      symbolOnly     - Generate only symbol
      symbolAndClass - (default) Generate symbol and AS3 class stub

    compress - Controls the compression of imported data.
      false - (default) Do not compress imported data.
      true  - Compress imported data with zlib.

  Superclass:
      flash.display.Bitmap - The superclass of the AS3 class stub.

  Example 1:
    Assuming that Binary import module is assigned to namespace bin the following snippet
    imports and then compresses /data/list.txt, exports it with symbolclass name
    resources.NameList and generates a corresponding AS3 class stub (default behavior):

      <bin:binary import=\"/data/list.txt\" class=\"resources.NameList\" compress=\"true\"/>

  Example 2:
    Manual creation of class stub. First import the file with genclass set to symbolOnly

      <bin:binary import=\"/data/list.txt\" class=\"resources.NameList\" genclass=\"symbolOnly\" compress=\"true\"/>

    then define the class stub in haXe:

      package resources;

      class NameList extends flash.utils.ByteArray {
        public function new() {
          super();
        }
      }';
   }

   public static function initModule(): Bool {
      return true;
   }
   
   public static function initInterface(version: String, moduleService : Dynamic): Void {
      
      var lm = neko.vm.Module.local();
      switch(version) {
         case "1.0.0":
            var module = new Binary();
            module.moduleService_1_0 = cast moduleService;

            lm.setExport(SamHaXeModule.IMPORT_FUN_1_0, module.import_binary_1_0);
            lm.setExport(SamHaXeModule.CHECK_FUN_1_0,  module.check_binary_1_0);
            lm.setExport(SamHaXeModule.HELP_FUN_1_0,   module.help_binary_1_0);

         default:
            throw "Unsupported interface version (" + version + ") requested!";
      }
   }
   
   static function getBinaryHashBase(data: haxe.io.Bytes, ?extra = ""): String {
      return extra + data.toString();
   }
   
   public static function main() {
      var lm = neko.vm.Module.local();
      
      lm.setExport(SamHaXeModule.INTERFACES,     interface_versions);
      lm.setExport(SamHaXeModule.DESCRIPTION,    description_binary);
      lm.setExport(SamHaXeModule.INIT_MODULE,    initModule);
      lm.setExport(SamHaXeModule.INIT_INTERFACE, initInterface);
   }
}
