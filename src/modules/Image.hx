/*
   Title: Image.hx
      Image import module for importing lossless and lossy compressed image files

   Section: image
      Imports specified image from an image file as TBitsLossless2 or TBitsJPEG2 swf tag.

      The import method (lossless or lossy) depends on the file type and is determinded automatically.
      Any image format supported by ImageMagick (<http://www.imagemagick.org/script/formats.php>) or
      DevIL (<http://openil.sourceforge.net/features.php>) - depending on your configuration - can be used.

   Mandatory attributes:
      import - Path to the file to be imported.
      class - Class name assigned to imported data.

   Optional attributes:
      genclass - (false, symbolOnly, _symbolAndClass_) Controls the generation of symbols and AS3 class stubs.
         Available values are:
            *false* (don't generate neither symbol nor AS3 class stub),
            *symbolOnly* (generate only symbol),
            *symbolAndClass* (generate symbol and AS3 class stub)
      mask - Relevant only for JPEGs ignored for lossless images. Path to the file containing the alpha mask.
             The dimensions of the image file and mask file has to be identical.

   Superclass:
      flash.display.Bitmap - The superclass of the AS3 class stub.

   Example 1:
      Assuming that Image import module is assigned to namespace _img_ the following snippet imports
      _flower.png_ as a lossless image, exports it with symbolclass name _resources.Flower_ and generates
      a corresponding AS3 class stub (default behavior):
      > <img:image import="flower.png" class="resources.Flower"/>

   Exampe 2:
      Import a JPEG file with an alpha mask:
      > <img:image import="background.jpg" mask="vignette.png" class="resources.BgImage"/>
   
   Example 3:
      Manual creation of class stub. First import the image file with _genclass_ set to _symbolOnly_
      > <img:image import="texture.jpg" class="resources.FloorTexture" genclass="symbolOnly"/>
      then define the class stub in haXe:
      (code)
      package resources;

      class FloorTexture extends flash.display.Bitmap {
         public function new() {
            super();
         }
      }
      (end)
*/
import haxe.xml.Check;
import neko.io.File;

import format.swf.Constants;
import format.swf.Data;

import SamHaXeModule;
import Helpers;
import ModuleService;

class Image {
   static var interface_versions = ["1.0.0"];
   
   static var description_image: String = "Image import module // (c) 2009 Mindless Labs";
   
   static var superclass = "flash.display.Bitmap";
   
   var moduleService_1_0 : ModuleService_1_0;

   public function new() {
   }
   
   public function check_image_1_0(image: NsFastXml): Void {
      var ns = image.ns + ":";

      var image_rule = RNode(ns + "image", [
         Att("import"),
         Att("class"),
         Att("genclass",
            FEnum([
               SamHaXeModule.GENCLASS_FALSE, 
               SamHaXeModule.GENCLASS_SYMBOL_ONLY, 
               SamHaXeModule.GENCLASS_SYMBOL_AND_CLASS
            ]), 
            SamHaXeModule.GENCLASS_SYMBOL_AND_CLASS
         ),  
         Att("mask", null, ""),
      ]);

      haxe.xml.Check.checkNode(image.x, image_rule);
   }
   
   public function import_image_1_0(image: NsFastXml, options: Hash<String>): Array<SWFTag> {
      var file_name = image.x.get("import");
      var lname = file_name.toLowerCase();

      if(lname.lastIndexOf(".jpg") == lname.length - 4 || lname.lastIndexOf(".jpeg") == lname.length - 5) {
         // Use JPEG import if the file extension is '.jpg' or '.jpeg'
         return load_jpeg(image);
      } else
         // Use lossless import otherwise
         return load_lossless(image);
   }

   public function help_image_1_0(): String {
      return
'Available XML tags:
  <image>: Imports specified image from an image file as TBitsLossless2 or TBitsJPEG2 swf tag.
      The import method (lossless or lossy) depends on the file type and is determinded automatically.
      Any image format supported by ImageMagick (http://www.imagemagick.org/script/formats.php) can be used.

  Mandatory attributes:
    import - Path to the file to be imported.
    class - Class name assigned to imported data.

  Optional attributes:
    genclass - Controls the generation of symbols and AS3 class stubs.
      false          - do not generate neither symbol nor AS3 class stub
      symbolOnly     - generate only symbol
      symbolAndClass - generate symbol and AS3 class stub
    
    mask - Relevant only for JPEGs ignored for lossless images. Path to the file containing the alpha mask.
           The dimensions of the image file and mask file has to be identical.

  Superclass:
    flash.display.Bitmap - The superclass of the AS3 class stub.

  Example 1:
    Assuming that Image import module is assigned to namespace img the following snippet imports
    flower.png as a lossless image, exports it with symbolclass name resources.Flower and generates
    a corresponding AS3 class stub (default behavior):
    
      <img:image import="flower.png" class="resources.Flower"/>

   Exampe 2:
      Import a JPEG file with an alpha mask:
        
        <img:image import="background.jpg" mask="vignette.png" class="resources.BgImage"/>
   
   Example 3:
      Manual creation of class stub. First import the image file with genclass set to symbolOnly

        <img:image import="texture.jpg" class="resources.FloorTexture" genclass="symbolOnly"/>

      then define the class stub in haXe:
      
        package resources;

        class FloorTexture extends flash.display.Bitmap {
          public function new() {
            super();
          }
        }';
   }

   function read_jpeg_file(jpeg_file: String): haxe.io.Bytes {
      var f = null;
      
      try { 
         f = neko.io.File.read(jpeg_file, true);
      }
      catch (e : Dynamic) {
         throw "File '" + jpeg_file + "' not found!";
      }

      /*
      f.bigEndian = true;

      var soi_pos: Int = -1;
      var eoi_pos: Int = -1;
      
      try {
         var first = f.readByte();
         
         while(!f.eof()) {
            if(first == 0xff) {
               // Found a marker
               var second = f.readByte();

               switch(second) {
                  // Standalone markers(no length field follows)
                  case 0x00, 0x01, 0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd7, 0xff:

                  // SOI marker(standalone)
                  case 0xd8:
                     soi_pos = f.tell() - 2;
                  
                  // EOI marker(standalone)
                  case 0xd9:
                     eoi_pos = f.tell() - 2;

                  default:
                     // Not a standalone marker, skip it's contents.
                     var length = f.readUInt16();
                     f.seek(length - 2, SeekCur);
               }

               // If the second byte is also 0xff then it's a padding and the next marker
               // may begin with this second 0xff
               if(second != 0xff)
                  first = f.readByte();
            } else
               first = f.readByte();
         }
      } catch(e: Dynamic) { }

      if(soi_pos == -1 || eoi_pos == -1 || soi_pos > eoi_pos)
         throw "Not found proper SOI and EOI markers!";

      f.seek(soi_pos, SeekBegin);
      var data = f.read(eoi_pos - soi_pos);
      f.close();
      */

      var data = f.readAll();
      f.close();

      return data;
   }

   function load_jpeg(image: NsFastXml): Array<SWFTag> {
      if(image.has.mask && image.att.mask.length > 0) {
         if(moduleService_1_0.getFlashVersion() < 3)
            throw "Importing JPEG images with alpha mask requires flash version 3 or higher!";
         
         var jpeg_file = image.x.get("import");
         var mask_file = image.att.mask;
         var image_info_fn = neko.Lib.load("image", "image_info", 1);
         var jpeg_info = neko.Lib.nekoToHaxe(image_info_fn(untyped jpeg_file.__s));
         var mask_info = neko.Lib.nekoToHaxe(image_info_fn(untyped mask_file.__s));

         if(jpeg_info.width + 0 != mask_info.width || jpeg_info.height + 0 != mask_info.height)
            throw "JPEG image('" + jpeg_file + "' " + jpeg_info.width + "x" + jpeg_info.height + ") and" +
                  "mask('" + mask_file + "' " + mask_info.width + "x" + mask_info.height + ") dimensions are differ";

         var import_mask_fn = neko.Lib.load("image", "import_mask", 1);
         var mask = import_mask_fn(untyped mask_file.__s);
         var jpeg_data = read_jpeg_file(jpeg_file);
         var mask_data = haxe.io.Bytes.ofString(neko.Lib.nekoToHaxe(mask.data));
            
         var should_gen_class = !image.has.genclass || image.att.genclass == SamHaXeModule.GENCLASS_SYMBOL_AND_CLASS;
         var should_store_symbol = should_gen_class || image.att.genclass == SamHaXeModule.GENCLASS_SYMBOL_ONLY;

         var package_name = moduleService_1_0.getVariableRegistry().getVariable("package");
         var class_name = (if(package_name.length > 0) package_name + "." else "") + image.x.get("class");
         var as3Reg = moduleService_1_0.getAS3Registry();
         var symReg = moduleService_1_0.getSymbolRegistry();

         var cid;
         var hashIdRes = Helpers.getIdForHashSymbolWarn(
            getJPEGHashBase(
               jpeg_data,
               // Use uncompressed data for hashing!
               mask_data
            ),
            TagId.DefineBitsJPEG3,
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
         
         moduleService_1_0.getDependencyRegistry().addFilePath(jpeg_file);
         moduleService_1_0.getDependencyRegistry().addFilePath(mask_file);

         return [TBitsJPEG(
            cid,
            JDJPEG3(jpeg_data, format.tools.Deflate.run(mask_data))
         )];

      } else {
         if(moduleService_1_0.getFlashVersion() < 2)
            throw "Importing JPEG images requires flash version 2 or higher!";

         var jpeg_file = image.x.get("import");
         var jpeg_data = read_jpeg_file(jpeg_file);
         
         var should_gen_class = !image.has.genclass || image.att.genclass == SamHaXeModule.GENCLASS_SYMBOL_AND_CLASS;
         var should_store_symbol = should_gen_class || image.att.genclass == SamHaXeModule.GENCLASS_SYMBOL_ONLY;

         var package_name = moduleService_1_0.getVariableRegistry().getVariable("package");
         var class_name = (if(package_name.length > 0) package_name + "." else "") + image.x.get("class");
         var as3Reg = moduleService_1_0.getAS3Registry();
         var symReg = moduleService_1_0.getSymbolRegistry();

         var cid;
         var hashIdRes = Helpers.getIdForHashSymbolWarn(
            getJPEGHashBase(
               jpeg_data
            ),
            TagId.DefineBitsJPEG2,
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
         
         moduleService_1_0.getDependencyRegistry().addFilePath(jpeg_file);

         return [TBitsJPEG(
            cid,
            JDJPEG2(jpeg_data)
         )];
      }
   }

   function load_lossless(image: NsFastXml): Array<SWFTag> {
      var image_file = image.x.get("import");
      var import_fn = neko.Lib.load("image", "import_image", 1);
      var img = null;
      try {
         img = import_fn(untyped image_file.__s);
      }
      catch (e : Dynamic) {
         throw "Could not import file '" + image_file + "', reason:\n" + Helpers.tabbed(e.toString());
      }

      if(img.alpha) {
         if(moduleService_1_0.getFlashVersion() < 3)
            throw "Importing lossless images with alpha channel requires flash version 3 or higher!";

      } else {
         if(moduleService_1_0.getFlashVersion() < 2)
            throw "Importing lossless images requires flash version 2 or higher!";
      }

      var cmodel = switch(img.bits) {
         // BitsLossless2 expects a value less than the actual used colors.
         case 8:  CM8Bits(img.colors - 1);
         case 24: CM24Bits;
         case 32: CM32Bits;
         default: throw "Invalid color model (BPP = "+img.bits+")";
      };

      // Uncompressed image data as haxe.io.Bytes
      var img_data = haxe.io.Bytes.ofString(neko.Lib.nekoToHaxe(img.data));
      var should_gen_class = !image.has.genclass || image.att.genclass == SamHaXeModule.GENCLASS_SYMBOL_AND_CLASS;
      var should_store_symbol = should_gen_class || image.att.genclass == SamHaXeModule.GENCLASS_SYMBOL_ONLY;

      var package_name = moduleService_1_0.getVariableRegistry().getVariable("package");
      var class_name = (if(package_name.length > 0) package_name + "." else "") + image.x.get("class");
      var as3Reg = moduleService_1_0.getAS3Registry();
      var symReg = moduleService_1_0.getSymbolRegistry();

      var w: Int = img.width;
      var h: Int = img.height;
      
      var cid: Int;
      var hashIdRes = Helpers.getIdForHashSymbolWarn(
         getLosslessHashBase(
            cmodel,
            img.width,
            img.height,
            // Use uncompressed data for hashing!
            img_data
         ),
         if(img.alpha) TagId.DefineBitsLossless2 else TagId.DefineBitsLossless,
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
      
      moduleService_1_0.getDependencyRegistry().addFilePath(image_file);

      return [
         if(img.alpha)
            TBitsLossless2({
               cid:     cid,
               color:   cmodel,
               width:   img.width,
               height:  img.height,
               data:    format.tools.Deflate.run(img_data)
            })
         else
            TBitsLossless({
               cid:     cid,
               color:   cmodel,
               width:   img.width,
               height:  img.height,
               data:    format.tools.Deflate.run(img_data)
            })
      ];
   }


   public static function initModule(): Bool {
      return true;
   }
   
   public static function initInterface(version: String, moduleService : Dynamic): Void {
      
      var lm = neko.vm.Module.local();
      switch(version) {
         case "1.0.0":
            var module = new Image();
            module.moduleService_1_0 = cast moduleService;
            
            lm.setExport(SamHaXeModule.IMPORT_FUN_1_0, module.import_image_1_0);
            lm.setExport(SamHaXeModule.CHECK_FUN_1_0,  module.check_image_1_0);
            lm.setExport(SamHaXeModule.HELP_FUN_1_0,   module.help_image_1_0);

         default:
            throw "Unsupported interface version (" + version + ") requested!";
      }
            
      var native_init_fn = neko.Lib.load("image", "init", 0);
      if(!native_init_fn())
         throw "Native image modul initialization failed!";
   }
     
   static function getLosslessHashBase(color: format.swf.ColorModel, width: Int, height: Int, data: haxe.io.Bytes, ?extra = "") : String {
      return Std.string(color) + Std.string(width) + Std.string(height) + extra + data.toString();
   }
   
   static function getJPEGHashBase(data: haxe.io.Bytes, ?mask: haxe.io.Bytes = null, ?extra = "") : String {
      return extra + data.toString() + (if(mask != null) mask.toString() else "");
   }
   
   public static function main() {
      var lm = neko.vm.Module.local();

      lm.setExport(SamHaXeModule.INTERFACES,     interface_versions);
      lm.setExport(SamHaXeModule.DESCRIPTION,    description_image);
      lm.setExport(SamHaXeModule.INIT_MODULE,    initModule);
      lm.setExport(SamHaXeModule.INIT_INTERFACE, initInterface);
   }
}
