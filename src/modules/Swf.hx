/*
   Title: Swf.hx
      Swf import module for importing other swf asset libraries

   Section: swf
      Imports tags from SWF files and rewrites character IDs to avoid ID collisions. Every SWF tag supported
      by format.swf are parsed, rewritten (if needed) and then serialized again. SWF tags concerning direct
      stage manipulation (PlaceObjectX for example) are grouped into a DefineSprite tag which is then
      appended after other tags.

   Mandatory attributes:
      import - Path to the file to be imported.
      class - Class name assigned to imported data.

   Optional attributes:
      genclass - (false, symbolOnly, _symbolAndClass_) Controls the generation of symbols and AS3 class stubs.
         Available values are:
            *false* (don't generate neither symbol nor AS3 class stub),
            *symbolOnly* (generate only symbol),
            *symbolAndClass* (generate symbol and AS3 class stub)

   Superclass:
      flash.display.MovieClip - The superclass of the AS3 class stub.

   Example 1:
      Assuming that Swf import module is assigned to namespace _swf_ the following snippet imports
      animation.swf as a MovieClip, exports it with symbolclass name _resources.Animation_ and generates
      a corresponding AS3 class stub (default behavior):
      > <swf:swf import="animation.swf" class="resources.Animation"/>

   Example 2:
      Manual creation of class stub. First import the swf file with _genclass_ set to _symbolOnly_
      > <swf:swf import="animation.swf" class="resources.Animation" genclass="symbolOnly"/>
      then define the class stub in haXe:
      (code)
      package resources;

      class Animation extends flash.display.MovieClip {
         public function new() {
            super();
         }
      }
      (end)

   Section: library
      Provides almost the same functionality as <swf> except it doesn't import stage manipulation tags at all.
      Moreover it doesn't generates neither symbol class nor AS3 class stubs. Useful for importing external
      libraries provided as binary SWF files.
      
   Mandatory attributes:
      import - Path to the file to be imported.

   Optional attributes:
      symbols - (_false_, true) Controls the inclusion of SymbolClass tag entries. Libraries generated
         with flex may include some non Sprite based class to character ID mappings which cause runtime
         errors in flash player.

   Superclass:
      No AS3 class stub is generated.

   Example:
      Assuming that Swf import module is assigned to namespace _swf_ the following snippet imports
      _extlib.swf_ as a library:
      > <swf:library import="extlib.swf"/>
*/
import haxe.xml.Check;
import format.swf.Data;
import format.swf.Constants;
import format.swf.Reader;

import SamHaXeModule;
import ModuleService;

class Swf {
   static var interface_versions = ["1.0.0"];

   static var description_swf: String = "Swf import module // (c) 2009 Mindless Labs";
   
   static var superclass: String = "flash.display.MovieClip";
   
   var moduleService_1_0 : ModuleService_1_0;

   //
   // Keeps track of rewritten character id's
   //
   var newCid : IntHash<Int>;

   public function new() {
   }
   
   public function check_swf_1_0(swf: NsFastXml): Void {
      var ns = swf.ns + ":";

      var bin_rule = RChoice([
         RNode(ns + "library", [
            Att("import"),
            Att("symbols", FBool, "false")
         ]),
         RNode(ns + "swf", [
            Att("class"),
            Att("import"),
            Att("genclass", FBool, "true")
         ])
      ]);
 
      haxe.xml.Check.checkNode(swf.x, bin_rule);
   }

   public function import_swf_1_0(swf_elem: NsFastXml, options: Hash<String>): Array<SWFTag> {
      var f = null;
      
      try { 
         f = neko.io.File.read(swf_elem.x.get("import"), true);
      }
      catch (e : Dynamic) {
         throw "File '" + swf_elem.x.get("import") + "' not found!";
      }
 
      var r = new format.swf.Reader(f);
      var swf = r.read();
      var hdr = swf.header;
      
      var isLib = swf_elem.lname == "library";

      // calc!

      newCid = new IntHash();
      
      var main_tags = new Array<SWFTag>();
      var clip_tags = new Array<SWFTag>();

      // warning! this renders the original
      // swf tag structure unusable
      walkTags(swf.tags, main_tags, clip_tags, (!isLib || !swf_elem.has.symbols || swf_elem.att.symbols == "true") );

      if (!isLib) {
         var id = moduleService_1_0.getIdRegistry().getNewId();
         var package_name = moduleService_1_0.getVariableRegistry().getVariable("package");
         var class_name = (if(package_name.length > 0) package_name + "." else "") + swf_elem.x.get("class");
         
         moduleService_1_0.getSymbolRegistry().addSymbol(id, class_name);
         
         main_tags.push(TClip(id, hdr.nframes, clip_tags));
         
         if(!swf_elem.has.genclass || swf_elem.att.genclass == "true") {
            var ctx = moduleService_1_0.getAS3Registry().getContext();
            var cl = ctx.beginClass(class_name, true);
            cl.superclass = ctx.type(superclass);
            ctx.endSubClass();
         }
      }
      
      moduleService_1_0.getDependencyRegistry().addFilePath(swf_elem.x.get("import"));

      return main_tags;

   }

   public function help_swf_1_0(): String {
      return
'Available XML tags:
  <swf>: Imports tags from SWF files and rewrites character IDs to avoid ID collisions. Every SWF tag supported
         by format.swf are parsed, rewritten (if needed) and then serialized again. SWF tags concerning direct
         stage manipulation (PlaceObjectX for example) are grouped into a DefineSprite tag which is then
         appended after other tags.

  Mandatory attributes:
    import - Path to the file to be imported.
    class  - Class name assigned to imported data.

  Optional attributes:
    genclass - Controls the generation of symbols and AS3 class stubs.
      false          - Do not generate neither symbol nor AS3 class stub.
      symbolOnly     - Generate only symbol
      symbolAndClass - (default) Generate symbol and AS3 class stub

  Superclass:
    flash.display.MovieClip - The superclass of the AS3 class stub.

  Example 1:
    Assuming that Swf import module is assigned to namespace swf the following snippet imports
    animation.swf as a MovieClip, exports it with symbolclass name resources.Animation and generates
    a corresponding AS3 class stub (default behavior):

      <swf:swf import="animation.swf" class="resources.Animation"/>

  Example 2:
    Manual creation of class stub. First import the swf file with genclass set to symbolOnly
      
      <swf:swf import="animation.swf" class="resources.Animation" genclass="symbolOnly"/>
      
    then define the class stub in haXe:
      
      package resources;

      class Animation extends flash.display.MovieClip {
         public function new() {
            super();
         }
      }
      

  <library>: Provides almost the same functionality as <swf> except it does not import stage manipulation
             tags at all. Moreover it does not generates neither symbol class nor AS3 class stubs. Useful
             for importing external libraries provided as binary SWF files.
      
  Mandatory attributes:
    import - Path to the file to be imported.

  Optional attributes:
    symbols - Controls the inclusion of SymbolClass tag entries.
      false - (default) Do not include SymbolClass mappings.
      true  - Include SymbolClass mappings.

  Superclass:
    No AS3 class stub is generated.

  Example:
    Assuming that Swf import module is assigned to namespace swf the following snippet imports
    extlib.swf as a library:
      
      <swf:library import="extlib.swf"/>';
   }

   function getCid(oldCid : Int) : Int {
      if (!newCid.exists(oldCid))
         newCid.set(oldCid, moduleService_1_0.getIdRegistry().getNewId());
      
      return newCid.get(oldCid);
   }

   function rewriteCid(data : haxe.io.Bytes) {
      var cid_i = new haxe.io.BytesInput(data.sub(0, 2));
      cid_i.bigEndian = false;
      var o = new haxe.io.BytesOutput();
      o.bigEndian = false;
      o.writeUInt16(getCid(cid_i.readUInt16()));
      data.blit(0, o.getBytes(), 0, 2);
      return data;
   }

   function rewriteFillStylesBitmapCid(fill_styles: Array<FillStyle>): Array<FillStyle> {
      var new_fs = new Array<FillStyle>();
      
      for(fs in fill_styles) {
         new_fs.push(switch(fs) {
            case FSBitmap(cid, mat, repeat, smooth):
               /*
                  For defining clipped bitmap filled shapes, 2 fillstyles are used:

                  The first one has a FillStyleType of 0x41, a bitmap id of 65535,
                  and a matrix that defines the mapping of pixels on to the geometry.

                  The second fillstyle has a FillStyleType of 0x41, the bitmap id of the image to use,
                  and a matrix that is applied to the outline geometry.
                  
                  The first Fillstyle can be eliminated.
                  It appears to be a bug in the authoring tool. (PH 99.01.05)

                  source: http://www.minigui.org/app/SWFfilereference.shtml
               */
               if(cid != 0xffff)
                  FSBitmap(getCid(cid), mat, repeat, smooth);
               else
                  FSBitmap(cid, mat, repeat, smooth);

            default:
               fs;
         });
      }

      return new_fs;
   }

   function walkTags(tags : Array<SWFTag>, main_tags : Array<SWFTag>, clip_tags : Array<SWFTag>, symbols: Bool) {
      var idReg = moduleService_1_0.getIdRegistry();
      var symReg = moduleService_1_0.getSymbolRegistry();

      for (t in tags) {
         switch (t) {
            //
            // Definition Tags
            //
            case TShape(id, d):
               // Rewrite bitmap character IDs in bitmap fill styles
               var shape = 
                  switch(d) {
                     case SHDShape1(b, s):
                        s;
                     case SHDShape2(b, s):
                        s;
                     case SHDShape3(b, s):
                        s;
                     case SHDShape4(s):
                        s.shapes;
               }
               shape.fillStyles = rewriteFillStylesBitmapCid(shape.fillStyles);

               var new_shape_records = new Array<ShapeRecord>();
               for(shr in shape.shapeRecords) {
                  new_shape_records.push(switch(shr){
                     case SHRChange(data):
                        if(data.newStyles != null)
                           data.newStyles.fillStyles = rewriteFillStylesBitmapCid(data.newStyles.fillStyles);

                        SHRChange(data);

                     default:
                        shr;
                  });
               }
               shape.shapeRecords = new_shape_records;

               main_tags.push(
                  TShape(getCid(id), switch(d) {
                     case SHDShape1(b, s):
                        SHDShape1(b, shape);

                     case SHDShape2(b, s):
                        SHDShape2(b, shape);

                     case SHDShape3(b, s):
                        SHDShape3(b, shape);

                     case SHDShape4(s):
                        s.shapes = shape;
                        SHDShape4(s);
                  })
               );
            
            case TBitsLossless(l):
               var hashIdRes = Helpers.getIdForHashSymbolWarn(
                  getLosslessHashBase(l.color, l.width, l.height, l.data),
                  TagId.DefineBitsLossless,
                  idReg
               );
               switch (hashIdRes) {
                  case HISWR_New(id):
                     newCid.set(l.cid, id);
                     
                     l.cid = getCid(l.cid);
                     main_tags.push(
                        TBitsLossless(l)
                     );
                  
                  case  HISWR_DataFound(id):
                     // found old cid, rewrite following cids to old cid
                     newCid.set(l.cid, id);
                  
                  default:
                     throw "illegal state";                     
               }

            case TBitsLossless2(l): 
               var hashIdRes = Helpers.getIdForHashSymbolWarn(
                  getLosslessHashBase(l.color, l.width, l.height, l.data),
                  TagId.DefineBitsLossless2,
                  idReg
               );
               switch (hashIdRes) {
                  case HISWR_New(id):
                     newCid.set(l.cid, id);
                     
                     l.cid = getCid(l.cid);
                     main_tags.push(
                        TBitsLossless2(l)
                     );
                  
                  case  HISWR_DataFound(id):
                     // found old cid, rewrite following cids to old cid
                     newCid.set(l.cid, id);
                  
                  default:
                     throw "illegal state";                     
               }

            case TJPEGTables(d):
               //
               // TODO: Merge JPEGTables + TBitsJPEGv1 to JPEGv2
               //
               main_tags.push(t);                  

            case TBitsJPEG(id, jdata):
               main_tags.push(
                  TBitsJPEG(getCid(id), jdata)
               );
               
            case TSound(s): 
               var hashIdRes = Helpers.getIdForHashSymbolWarn(
                  getSoundHashBase(
                     s.format,
                     s.rate,
                     s.is16bit,
                     s.isStereo,
                     switch (s.data) {
                        case SDMp3(seek, d): d;
                        case SDRaw(d): d;
                        case SDOther(d): d;
                     },
                     switch (s.data) {
                        case SDMp3(seek, d): Std.string(seek);
                        default: null;
                     }
                  ),
                  TagId.DefineSound,
                  idReg
               );
               
               switch (hashIdRes) {
                  case HISWR_New(id):
                     newCid.set(s.sid, id);
                     
                     s.sid = getCid(s.sid);
                     main_tags.push(
                        TSound(s)
                     );
                  
                  case  HISWR_DataFound(id):
                     // found old sid, rewrite following sids to old sid
                     newCid.set(s.sid, id);
                  
                  default:
                     throw "illegal state";                     
               }
                  
            case TClip(id, frames, tags):
               var clip_tags = new Array<SWFTag>();
               walkTags(tags, main_tags, clip_tags, symbols);
               
               main_tags.push(
                  TClip(getCid(id), frames, clip_tags)
               );

            case TBinaryData(id, data):
               main_tags.push(
                  TBinaryData(getCid(id), data)
               );
  
            case TDoInitActions(id, d):
               main_tags.push(
                  TDoInitActions(getCid(id), d)
               );

            case TFont(id, d):
               main_tags.push(
                  TFont(getCid(id), d)
               );

            case TFontInfo(id, d):
               main_tags.push(
                  TFontInfo(getCid(id), d)
               );
           
            //
            // Special tags
            //
            case TActionScript3(d, c):
               main_tags.push(t);
 
            case TSymbolClass(syms),  TExportAssets(syms):
               // Add to the symbol registry instead of directly copying
               
               // XXX: Note: Multiple class defs for the same classname may still
               // be present

               if(symbols) {
                  for (sym in syms) {
                     sym.cid = getCid(sym.cid);
                     symReg.addSymbol(sym.cid, sym.className);
                  }
               }

            //
            // Control Tags
            //
            case TPlaceObject2(po):
               if(po.cid != null)
                  po.cid = getCid(po.cid);
               clip_tags.push(
                  TPlaceObject2(po)
               );
 
            case TPlaceObject3(po):
               if(po.cid != null)
                  po.cid = getCid(po.cid);
               clip_tags.push(
                  TPlaceObject3(po)
               );

            //
            // Leave these out
            //
            case TBackgroundColor(c):

            case TSandBox(_,_,_,_,_):

            //
            // Special handling
            //
            default:
               // check
               // No appropriate enum constructor for these tags
               // in hxformat yet.
               switch (t) {
                  case TUnknown(tid, data):
                     switch (tid) {
                        // These tags go into the root.
                        case
                           TagId.DefineFontAlignZones,
                           TagId.DefineFontName,
                           TagId.DefineText,
                           TagId.DefineText2,
                           TagId.DefineEditText,
                           TagId.CSMTextSettings,
                           TagId.DefineFont4:

                           main_tags.push(
                              TUnknown(tid, rewriteCid(data))
                           );

                        // Leve these out
                        case TagId.DefineSceneAndFrameLabelData:
                        
                        // These tags go inside the MovieClip
                        default:
                           clip_tags.push(t);
                     }
                  default:
                     clip_tags.push(t);
               }
         };
      }
   }

   static function getLosslessHashBase(color: format.swf.ColorModel, width: Int, height: Int, data: haxe.io.Bytes, ?extra = "") : String {
      return Std.string(color) + Std.string(width) + Std.string(height) + extra + data.toString();
   }
   
   static function getSoundHashBase(
      format: format.swf.SoundFormat,
      rate: format.swf.SoundRate,
      is16bit: Bool,
      isStereo: Bool,
      data: haxe.io.Bytes,
      ?extra = ""
   ) : String {
      return Std.string(format) + Std.string(rate) + Std.string(is16bit) + Std.string(isStereo) + extra + data.toString();
   }

   public static function initModule(): Bool {
      return true;
   }
   
   public static function initInterface(version: String, moduleService : Dynamic): Void {
      
      var lm = neko.vm.Module.local();
      switch(version) {
         case "1.0.0":
            var module = new Swf();
            module.moduleService_1_0 = cast moduleService;

            lm.setExport(SamHaXeModule.IMPORT_FUN_1_0, module.import_swf_1_0);
            lm.setExport(SamHaXeModule.CHECK_FUN_1_0,  module.check_swf_1_0);
            lm.setExport(SamHaXeModule.HELP_FUN_1_0,   module.help_swf_1_0);

         default:
            throw "Unsupported interface version (" + version + ") requested!";
      }
   }
   
   public static function main() {
      var lm = neko.vm.Module.local();

      lm.setExport(SamHaXeModule.INTERFACES,     interface_versions);
      lm.setExport(SamHaXeModule.DESCRIPTION,    description_swf);
      lm.setExport(SamHaXeModule.INIT_MODULE,    initModule);
      lm.setExport(SamHaXeModule.INIT_INTERFACE, initInterface);
   }
}
