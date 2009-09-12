/*
   Title: Sound.hx
      Sound import module for importing wav and mp3 sound files.

   Section: sound
      Imports a wav or mp3 file as DefineSound swf tag.

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
      flash.media.Sound - The superclass of AS3 class stub.

   Example 1:
      Assuming that Sound import module is assigned to namespace _snd_ the following snippet imports
      pickup.mp3, exports it with symbolclass name _resources.PickupSound_ and generates a corresponding
      AS3 class stub (default behavior):
      
   >  <snd:sound import="pickup.mp3" class="resources.PickupSound"/>

   Example 2:
      Manual creation of class stub. First import the file with _genclass_ set to _symbolOnly_
   >  <snd:sound import="explode.wav" class="resources.ExplodeSound" genclass="symbolOnly"/>
      then define the class stub in haXe:
      (code)
      package resources;

      class ExplodeSound extends flash.media.Sound {
         public function new() {
            super();
         }
      }
      (end)
*/
import haxe.xml.Check;
import format.swf.Data;
import format.swf.Constants;
import format.mp3.Data;
import format.wav.Data;

import SamHaXeModule;
import Helpers;
import ModuleService;

class Sound {
   static var interface_versions = ["1.0.0"];
   
   static var description_sound: String = "Sound import module // (c) 2009 Mindless Labs";

   static var superclass: String = "flash.media.Sound";
   
   var moduleService_1_0 : ModuleService_1_0;

   public function new() {
   }

   public function check_sound_1_0(sound: NsFastXml): Void {
      var ns = sound.ns + ":";

      var sound_rule = RNode(ns + "sound", [
         Att("import"),
         Att("class"),
         Att("genclass",
            FEnum([
               SamHaXeModule.GENCLASS_FALSE, 
               SamHaXeModule.GENCLASS_SYMBOL_ONLY, 
               SamHaXeModule.GENCLASS_SYMBOL_AND_CLASS
            ]), 
            SamHaXeModule.GENCLASS_SYMBOL_AND_CLASS
         )
      ]);
      
      haxe.xml.Check.checkNode(sound.x, sound_rule);
   }

   public function import_sound_1_0(sound: NsFastXml, options: Hash<String>) : Array<SWFTag> {
      var file_name = sound.x.get("import");
      var lname = file_name.toLowerCase();

      if (lname.lastIndexOf(".mp3") == lname.length - 4) {
         return load_mp3(sound);
      }
      else if (lname.lastIndexOf(".wav") == lname.length - 4) {
         return load_wav(sound);
      }
      else
         throw "Only mp3 and wav are supported\nPlease make sure filename ends in .mp3 or .wav";
   }
   
   public function help_sound_1_0(): String {
      return
'Available XML tags:
  <sound>: Imports a wav or mp3 file as DefineSound swf tag.

  Mandatory attributes:
    import - Path to the file to be imported.
    class  - Class name assigned to imported data.

  Optional attributes:
    genclass - Controls the generation of symbols and AS3 class stubs.
      false          - Do not generate neither symbol nor AS3 class stub.
      symbolOnly     - Generate only symbol
      symbolAndClass - (default) Generate symbol and AS3 class stub

  Superclass:
    flash.media.Sound - The superclass of AS3 class stub.

  Example 1:
    Assuming that Sound import module is assigned to namespace snd the following snippet imports
    pickup.mp3, exports it with symbolclass name resources.PickupSound and generates a corresponding
    AS3 class stub (default behavior):
      
      <snd:sound import="pickup.mp3" class="resources.PickupSound"/>

  Example 2:
    Manual creation of class stub. First import the file with genclass set to symbolOnly
      
      <snd:sound import="explode.wav" class="resources.ExplodeSound" genclass="symbolOnly"/>
      
    then define the class stub in haXe:

      package resources;

      class ExplodeSound extends flash.media.Sound {
        public function new() {
          super();
        }
      }';
   }

   function load_mp3(sound: NsFastXml) : Array<SWFTag> {
      var file_name = sound.x.get("import");
      var f;
      
      try {
         f = neko.io.File.read(file_name, true);
      }
      catch (e : Dynamic) {
         throw "Could not open file '" + file_name + "' for reading." ;
      }

      // When to generate class def, symbol
      var should_gen_class = !sound.has.genclass || sound.att.genclass == SamHaXeModule.GENCLASS_SYMBOL_AND_CLASS;
      var should_store_symbol = should_gen_class || sound.att.genclass == SamHaXeModule.GENCLASS_SYMBOL_ONLY;

      // Parse mp3
      var r = new format.mp3.Reader(f);
      var mp3 = r.read();
      
      if (mp3.frames.length == 0)
         throw "No frames found in mp3: " + file_name;

      // Guess about the format based on the header of the first frame found
      var fr0 = mp3.frames[0];
      var hdr0 = fr0.header;

      // Verify Layer3-ness
      if (hdr0.layer != Layer.Layer3)
         throw "Only Layer-III mp3 files are supported by flash. File " + file_name + " is: " + format.mp3.Tools.getFrameInfo(fr0);

      // Check sampling rate
      var flashRate = switch (hdr0.samplingRate) {
         case SR_11025: SR11k;
         case SR_22050: SR22k;
         case SR_44100: SR44k;
         default:
            throw "Only 11025, 22050 and 44100 Hz mp3 files are supported by flash. File " + file_name + " is: " + format.mp3.Tools.getFrameInfo(fr0);
      }

      var isStereo = switch (hdr0.channelMode) {
         case Stereo, JointStereo, DualChannel: true;
         case Mono: false;
      };

      // Should we do this? For now, let's do.
      var write_id3v2 = true;

      var rawdata = new haxe.io.BytesOutput();
      (new format.mp3.Writer(rawdata)).write(mp3, write_id3v2);
      var dataBytes = rawdata.getBytes();

      // Request an id, also check for multiple imports 
      
      var package_name = moduleService_1_0.getVariableRegistry().getVariable("package");
      var class_name = (if(package_name.length > 0) package_name + "." else "") + sound.x.get("class");
      var symReg = moduleService_1_0.getSymbolRegistry();

      // Get SID
      // This will also generate the symbol and warn about collisions
      // if we pass a valid symReg and classname
      
      var sid;

      var hashIdRes = Helpers.getIdForHashSymbolWarn(
         getSoundHashBase(
            SFMP3,
            flashRate,
            true,
            isStereo,
            dataBytes,
            Std.string(0) // 'seek' param passed in 'extra' argument
         ),
         TagId.DefineSound,
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
               Helpers.generateClass(moduleService_1_0.getAS3Registry(), class_name, superclass);
             return [];

         case HISWR_New(id):
            if (should_gen_class)
               Helpers.generateClass(moduleService_1_0.getAS3Registry(), class_name, superclass);
            
            sid = id;
            // Continue import

         case HISWR_NewOnlyData(id):
            sid = id;
            // Continue import
      }

      // Create the tag to return
      var snd : format.swf.Sound = {
         sid : sid,
         format : SFMP3,
         rate : flashRate,
         is16bit : true,
         isStereo : isStereo,
         samples : haxe.Int32.ofInt(mp3.sampleCount),
         data : SDMp3(0, dataBytes)
      }
      
      // Register file dependency
      moduleService_1_0.getDependencyRegistry().addFilePath(file_name);
     
      return [TSound(snd)];
   }
 
   function load_wav(sound: NsFastXml) : Array<SWFTag> {
      var file_name = sound.x.get("import");
      var f;
      
      try {
         f = neko.io.File.read(file_name, true);
      }
      catch (e : Dynamic) {
         throw "Could not open file '" + file_name + "' for reading." ;
      }

      // When to generate class def, symbol
      var should_gen_class = !sound.has.genclass || sound.att.genclass == SamHaXeModule.GENCLASS_SYMBOL_AND_CLASS;
      var should_store_symbol = should_gen_class || sound.att.genclass == SamHaXeModule.GENCLASS_SYMBOL_ONLY;

      var r = new format.wav.Reader(f);
      var wav = r.read();
      var hdr = wav.header;

      if (hdr.format != WF_PCM) 
         throw "Only PCM (uncompressed) wav files can be imported.";

      // Check sampling rate
      var flashRate = switch (hdr.samplingRate) {
         case  5512: SR5k;
         case 11025: SR11k;
         case 22050: SR22k;
         case 44100: SR44k;
         default:
            throw "Only 5512, 11025, 22050 and 44100 Hz wav files are supported by flash. Sampling rate of '" + file_name + "' is: " + hdr.samplingRate;
      }

      var isStereo = switch(hdr.channels) {
         case 1: false;
         case 2: true;
         default: throw "Number of channels should be 1 or 2, but for '" + file_name + "' it is " + hdr.channels;
      }
 
      var is16bit = switch(hdr.bitsPerSample) {
         case 8: false;
         case 16: true;
         default: throw "Bits per sample should be 8 or 16, but for '" + file_name + "' it is " + hdr.bitsPerSample;
      }

      var sampleCount = Std.int(wav.data.length / (hdr.bitsPerSample / 8));


      // Request an id, also check for multiple imports 

      var package_name = moduleService_1_0.getVariableRegistry().getVariable("package");
      var class_name = (if(package_name.length > 0) package_name + "." else "") + sound.x.get("class");
      var symReg = moduleService_1_0.getSymbolRegistry();
 
      // Get SID
      // This will also generate the symbol and warn about collisions
      // if we pass a valid symReg and classname
      
      var sid;

      var hashIdRes = Helpers.getIdForHashSymbolWarn(
         getSoundHashBase(
            SFLittleEndianUncompressed,
            flashRate,
            is16bit,
            isStereo,
            wav.data
         ),
         TagId.DefineSound,
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
               Helpers.generateClass(moduleService_1_0.getAS3Registry(), class_name, superclass);
             return [];

         case HISWR_New(id):
            if (should_gen_class)
               Helpers.generateClass(moduleService_1_0.getAS3Registry(), class_name, superclass);
            
            sid = id;
            // Continue import
         
         case HISWR_NewOnlyData(id):
            sid = id;
            // Continue import
      }


      // Create the tag to return
      var snd : format.swf.Sound = {
         sid : sid,
         format : SFLittleEndianUncompressed,
         rate : flashRate,
         is16bit : is16bit,
         isStereo : isStereo,
         samples : haxe.Int32.ofInt(sampleCount),
         data : SDRaw(wav.data)
      }

      moduleService_1_0.getDependencyRegistry().addFilePath(file_name);

      return [TSound(snd)];
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
            var module = new Sound();
            module.moduleService_1_0 = cast moduleService;

            lm.setExport(SamHaXeModule.IMPORT_FUN_1_0, module.import_sound_1_0);
            lm.setExport(SamHaXeModule.CHECK_FUN_1_0,  module.check_sound_1_0);
            lm.setExport(SamHaXeModule.HELP_FUN_1_0,   module.help_sound_1_0);

         default:
            throw "Unsupported interface version (" + version + ") requested!";
      }
   }
   
   public static function main() {
      var lm = neko.vm.Module.local();

      lm.setExport(SamHaXeModule.INTERFACES,     interface_versions);
      lm.setExport(SamHaXeModule.DESCRIPTION,    description_sound);
      lm.setExport(SamHaXeModule.INIT_MODULE,    initModule);
      lm.setExport(SamHaXeModule.INIT_INTERFACE, initInterface);
   }
}
