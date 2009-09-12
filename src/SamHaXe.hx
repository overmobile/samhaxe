/*
   Title: SamHaXe.hx
      Main source file.
*/
import format.abc.Data;
import format.swf.Data;
import Optparse;
import IdRegistry;
import SamHaXeModule;

/*
   Anonymous: ModuleHelpPars
      Container for module help parameters.
*/
typedef ModuleHelpPars = {
   /*
      Variable: module
         Name of module.
   */
   module: String,

   /*
      Variable: if_version
         Requested interface version.
   */
   if_version: String,

   /*
      Variable: flash_version
         Requested flash version.
   */
   flash_version: Int
};

/*
   Anonymous: Options
      Container for parsed command line options.
*/
typedef Options = {
   /*
      Variable: help
         Specifies if help message should be printed

      Related command line options:
         - -h
         - --help
   */
   help: Bool,

   /*
      Variable: configfile
         Specifies the config file to use

      Related command line options:
         - -c
         - --config
   */
   configfile: String,

   /*
      Variable: depfile
         Name of dependency tracking file or null if no dependency tracking requested.

      Related command line options:
         - -d
         - --depfile
   */
   depfile: String,

   /*
      Variable: modopts
         Options passed to import modules.

      Related command line options:
         - -m
         - --module-options
   */
   modopts: Hash<Hash<String>>,

   /*
      Variable: modlist
         Specifies if module list should be printed.

      Related command line options:
         - -l
         - --module-list
   */
   modlist: Bool,

   /*
      Variable: modhelp
         Stores the list of modules and the associated flash version
         whose detailed help message will be printed.

      Related command line options:
         - --module-help
   */
   modhelp: Array<ModuleHelpPars>
};

/*
   Class: SamHaXe
      Main application class

   Implemented interfaces:
      - <IdRegistry>
      - <SymbolRegistry>
      - <AS3Registry>
      - <DependencyRegistry>
      - <VariableRegistry>
*/
class SamHaXe implements IdRegistry, implements SymbolRegistry, implements AS3Registry, implements DependencyRegistry, implements VariableRegistry
   {
   /*
      Group: variables

      Variable: supported_interface_versions
         List of supported module interface versions.

         Currently there's only one module interface version (1.0) but in the future
         more versions might be added whose member functions may differ in parametrisation
         name, etc. The version "1.1" is added only for test purposes. <Compose.hx> module uses
         module interface version "1.1" to demonstrate supporting two interface simultaneously.
         This list contains all of those versions which the current implementation
         can handle.
   */
   static inline var supported_interface_versions = ["1.0", "1.1"];

   static inline var SHX_NS = "shx";

   var ids: IntHash<Bool>;
   var hashtag2id: Hash<Int>; // hashtag is 'md5 hash' + string(tagId)
   var next_id: Int;

   var config : Config;
   var ns2module: Hash<SamHaXeModule>;
   var flash_version : Int;
   var symbols: Hash<Int>;
   var cid2symbol: IntHash<String>;
   var frame_symbols: Array<{cid: Int, className: String}>;

   var frame_as3: format.abc.Context;

   var package_name : String;
   var dependencies: Hash<Bool>;
   var variables: Hash<Dynamic>;
   
   var options: Options;

   /*
      Group: methods

      Constructor: new
         Does all the work right now.
   */
   public function new() {
      ids = new IntHash<Bool>();
      hashtag2id = new Hash<Int>();
      next_id = 1;

      symbols = new Hash<Int>();
      cid2symbol = new IntHash();
      frame_symbols = null;

      dependencies = new Hash<Bool>();
      variables = new Hash<Dynamic>();
         
      options = {
         help: false,
         configfile: null,
         depfile: null,
         modopts: new Hash<Hash<String>>(),
         modlist: false,
         modhelp: new Array<ModuleHelpPars>()
      };

      var optparse = new Optparse();

      optparse.addOption("-c", "--config", "configfile", Optparse.readerString, Optparse.writerStore, "If given, config is read from the specified file.", "<config file name>");
      optparse.addOption("-d", "--depfile", "depfile", Optparse.readerString, Optparse.writerStore, "If given, resource dependecies will be written into the specified file.", "<file name>");
      optparse.addOption("-m", "--module-options", "modopts", Optparse.readerKVArray, writerModuleOptions, "The specified options are passed to the specified import module. (Exaple: Binary:myopt=somevalue)", "module:key=value[:key=value:...]");
      optparse.addOption("-h", "--help", "help", Optparse.readerNull, Optparse.writerStoreTrue, "Display this help message.");
      optparse.addOption("-l", "--module-list", "modlist", Optparse.readerNull, Optparse.writerStoreTrue, "List all import modules with a short description.");
      optparse.addOption(null, "--module-help", "modhelp", Optparse.readerKVArray, writerModuleHelp, "Prints help message of listed modules.", "module[=interface_version[;flash_version]][:module[=interface_version[;flash_version]]...]");

      var args = neko.Sys.args();
      var args_start: Int;

      try {
         args_start = optparse.parse(options, args);
      } catch(e: OptparseException) {
         neko.Lib.println(e);
         return;
      }

      if(!options.modlist && options.modhelp.length == 0 && (options.help || args_start > args.length - 2)) {
         neko.Lib.println("Usage: SamHaXe [options] <resources.xml> <assets.swf>\n");
         neko.Lib.println(optparse.getHelp());
         return;
      }

      config = new Config(supported_interface_versions, getModuleService);
      try {
         if(options.configfile != null)
            config.load(options.configfile);
         else {
            #if WINDOWS
            var config_file = neko.io.Path.directory(neko.Sys.executablePath()) + "/samhaxe.conf.xml";

            #else
            var config_file = "~/.samhaxe.conf.xml";
            if(!neko.FileSystem.exists(config_file))
               config_file = "/etc/samhaxe.conf.xml";
            #end
            
            config.load(config_file);
         }
      } catch(e: Dynamic) {
         neko.Lib.println(e);
         return;
      }

      if(options.modlist) {
         var mlist = new Array<{name: String, description: String}>();
         for(module_name in config.modules()) {
            var uri = config.getModuleUri(module_name);
            if(uri == null)
               throw "Module '"+module_name+"' found!";
            var module = config.getModule(uri);
            var desc = module.getDescription();
            mlist.push({
               name: module.name,
               description: if(desc == null) "No description available!" else desc
            });
         }

         mlist.sort(function(a, b) {
            return Reflect.compare(a.name, b.name);
         });

         neko.Lib.println("Available modules:\n");
         for(module in mlist) {
            neko.Lib.println("-" + module.name);
            neko.Lib.println(Helpers.tabbed(module.description) + "\n");
         }

         return;
      }

      if(options.modhelp.length > 0) {
         neko.Lib.println("=== Module Help ===\n");

         for(h in options.modhelp) {
            var uri = config.getModuleUri(h.module);
            if(uri == null)
               throw "Module '"+h.module+"' not found!";
            
            if(h.if_version != null)
               uri += "#" + h.if_version;
            config.getModule(uri);
            
            // Set flash version so the module will be initialized with
            // the requested version.
            flash_version = h.flash_version;
            config.initModule(uri);
            
            neko.Lib.println("- " + h.module + " (flash version " + flash_version + ")");

            var help_fn = config.getModule(uri).getHelpFunction();
            if(help_fn != null)
               neko.Lib.println(Helpers.tabbed(help_fn()));
            else
               neko.Lib.println("   No help available!");
            neko.Lib.print("\n");
         }

         return;
      }

      var resource_xml_data: String;
      try {
         resource_xml_data = neko.io.File.getContent(args[args_start]);
      } catch(e: Dynamic) {
         neko.Lib.println("Unable to open resource file: " + args[args_start]);
         return;
      }
            
      var r_xml = Xml.parse(resource_xml_data);
      var r_fast = new NsFastXml(r_xml.firstElement());
      var r_root = r_xml.firstElement();
      
      package_name = if(r_root.exists("package") && r_root.get("package").length > 0) r_root.get("package") else "";
      setVariable("package", package_name);

      // Assign namespaces to modules
      ns2module = new Hash<SamHaXeModule>();
      try {
         for(att in r_root.attributes()) {
            if(att.substr(0, 5) != "xmlns")
               continue;

            var ns = att.substr(6);
            if(ns != SHX_NS) {
               var uri = r_root.get(att);
               var module = config.getModule(uri);

               if(module != null)
                  ns2module.set(ns, module);
               else
                  neko.Lib.println("Warning: no module found for URI: " + uri);
            }
         }
      } catch(e: Dynamic) {
         neko.Lib.println(e);
         return;
      }

      // Acquire the requested flash version so modules can be fully initialized.
      flash_version = Std.parseInt(r_fast.att.version);
      config.initAllModules();
      
      // Check syntax of resources.xml
      try {
         for(frame in r_fast.qnodes(SHX_NS, "frame")) {

            for(asset in frame.elements) {
               var ns = asset.ns;
               var module = ns2module.get(ns);

               if(module != null) {
                  var check_fn = module.getCheckFunction();
                  if(check_fn != null)
                     try {
                        check_fn(asset);
                     }
                     catch (e : Dynamic) {
                        var preview = Helpers.tabbed(Helpers.expandtabs(asset.x.toString()));
                        throw "Check error in:\n" + preview + "\n\n" + Helpers.tabbed(e.toString());
                     }
               } else
                  neko.Lib.println("Warning: no module found for namespace: " + ns);
            }
         }

      } catch (e: Dynamic) {
         neko.Lib.println(e);
         return;
      }

      var swf_file = neko.io.File.write(args[args_start + 1], true);
      var swf_writer = new format.swf.Writer(swf_file);

      swf_writer.writeHeader({
         version: flash_version,
         compressed: (r_fast.att.compress.toLowerCase() == "true"),
         width: 100,
         height: 300,
         fps: 30,
         nframes: r_fast.qnodes(SHX_NS, "frame").length
      });
      
      swf_writer.writeTag(TSandBox(
         false,   // Fp10 direct blit
         false,   // Fp10 use gpu
         true,    // Fp10 HasMeta, Fp9 UseSymbolClass
         true,    // UseAs3
         false    // UseNetwork
      ));

      for(frame in r_fast.qnodes(SHX_NS, "frame")) {
         frame_symbols = null;
         frame_as3 = null;

         for(asset in frame.elements) {
            var tag_info = null;
            
            #if !DEBUG
            try {
            #end
               tag_info = runImport(asset);
            #if !DEBUG
            }
            catch (e : Dynamic) {
               //
               // Would be better to halt process entirely since
               // symbolclasses, ids, as3 etc. are already registered
               // and could cause trouble
               //
               neko.Lib.print("Skipping import of an asset, error:\n" +
                  Helpers.tabbed(e.toString()) + "\n");
            }
            #end
            
            if (tag_info != null)
               for(tag in tag_info) {
                  //trace(format.swf.Tools.dumpTag(tag, 50));
                  swf_writer.writeTag(tag);
               }
         }

         if(frame_symbols != null)
            swf_writer.writeTag(TSymbolClass(frame_symbols));

         if(frame_as3 != null) {
            frame_as3.finalize();

            var abc = new haxe.io.BytesOutput();
            format.abc.Writer.write(abc, frame_as3.getData());
            swf_writer.writeTag(TActionScript3(abc.getBytes()));
         }

         swf_writer.writeTag(TShowFrame);
      }

      swf_writer.writeEnd();

      if(options.depfile != null) {
         var f = neko.io.File.write(options.depfile, false);

         for(d in dependencies.keys())
            f.writeString(d + "\n");

         f.close();
      }
   }

   /*
      Function: runImport
         Invokes the import mechanism of the module associated
         with the asset. This involves registering Id's and AS3 code.

      Parameters:
         asset - the asset to be imported

      Returns:
         the swf taglist of the asset
   */
   public function runImport(asset: NsFastXml) : Array<SWFTag> {
      var ns = asset.ns;
      var module = ns2module.get(ns);

      if(module != null) {
         var import_fn = module.getImportFunction();
         
         //if (asset.x.exists("import"))
         //   dependencies.set(asset.x.get("import"), true);

         // Override options specified in XML with command line options for the import module
         /*
         if(options.modopts.exists(module.name)) {
            for(o in options.modopts.get(module.name)) {
               asset.x.set(o.key, o.value);
            }
         }
         */

         // Insert package name before class name
         //if (asset.has.id)
         //   asset.x.set("id", package_name + asset.att.id);

         var tag_info: Array<SWFTag>;
         
         #if !DEBUG
         try {
         #end
            tag_info = import_fn(asset, options.modopts.get(module.name));

         #if !DEBUG
         } catch(e: Dynamic) {
            var preview = Helpers.tabbed(Helpers.expandtabs(asset.x.toString()));
            throw "Import error in:\n" + preview + "\n\n" + Helpers.tabbed(e.toString());
         }
         #end

         return tag_info;

      }
      else {
         neko.Lib.print("Unknown resource namespace '" + ns + "' skipping...\n");
         return new Array<SWFTag>();
      }
   }

   /*
      Function: getModuleService
         Returns an instance of requested version of module service.

      Parameters:
         if_version - the module interface version requested

      Returns:
         The module service instance.
   */
   public function getModuleService(if_version : String) : Dynamic {
      var me = this;

      switch (Helpers.stripBugfixVersion(if_version)) {
         case "1.0", "1.1":
            return {
               getFlashVersion: function() return me.flash_version,
               getIdRegistry: function() return me,
               getSymbolRegistry: function() return me,
               getAS3Registry: function() return me,
               getDependencyRegistry: function() return me,
               getVariableRegistry: function() return me,
               runImport: runImport,
            }

         default:
            throw "Unknown interface version requested: " + if_version;
      }
   }

   /*
      Group: IdRegistry interface methods

      Function: idExists
         See <IdRegistry.idExists>
   */
   public function idExists(id: Int): Bool {
      return ids.exists(id);
   }

   /*
      Function: getNewId
         See <IdRegistry.getNewId>
   */
   public function getNewId(): Int {
      while(ids.exists(next_id))
         next_id++;

      ids.set(next_id, true);
      var id = next_id;
      next_id++;

      return id;
   }

   /*
      Function: getIdForHash
         See <IdRegistry.getIdForHash>
   */
   public function getIdForHash(md5: String, tagId: Int) : BytesIdLookupResult {
      var hashtag = md5 + Std.string(tagId);
      
      if (!hashtag2id.exists(hashtag)) {
         var id = getNewId();
         hashtag2id.set(hashtag, id);
         return BILR_New(id);
      }
      
      return BILR_Found(hashtag2id.get(hashtag));
   }

   /*
      Group: SymbolRegistry interface methods
      
      Function: symbolExists
         See <SymbolRegistry.symbolExists>
   */
   public function symbolExists(symbol: String): Bool {
      return symbols.exists(symbol);
   }

   /*
      Function: addSymbol
         See <SymbolRegistry.addSymbol>
   */
   public function addSymbol(cid: Int, symbol: String, ?store = true): Void {
      if (symbols.exists(symbol)) {
         // TODO: Logger service
         neko.Lib.print("[WARN] Trying to reassign symbol '" + symbol + "' (CID " + symbols.get(symbol) + " -> " + cid + "), not allowing this.\n");
         return;
      }

      symbols.set(symbol, cid);
      cid2symbol.set(cid, symbol);

      if (store) {
         if(frame_symbols == null)
            frame_symbols = new Array<{cid: Int, className: String}>();

         frame_symbols.push({cid: cid, className: symbol});
      }
   }

   /*
      Function: getSymbolCid
         See <SymbolRegistry.getSymbolCid>
   */
   public function getSymbolCid(symbol: String): Int {
      return symbols.get(symbol);
   }
   
   /*
      Function: getCidSymbol
         See <SymbolRegistry.getCidSymbol>
   */
   public function getCidSymbol(cid: Int): Null<String> {
      return cid2symbol.get(cid);
   }

   /*
      Group: AS3Registry interface methods
      
      Function: getContext
         See <AS3Registry.getContext>
   */
   public function getContext(): format.abc.Context {
      if(frame_as3 == null)
         frame_as3 = new format.abc.Context();

      return frame_as3;
   }

   /*
      Group: DependencyRegistry interface methods
      
      Function: addFilePath
         See <DependencyRegistry.addFilePath>
   */
   public function addFilePath(p: String): Void {
      dependencies.set(p, true);
   }
   
   /*
      Group: VariableRegistry interface methods
      
      Function: getVariable
         See <VariableRegistry.getVariable>
   */
   public function getVariable(name: String): Dynamic {
      return variables.get(name);
   }

   /*
      Function: setVariable
         See <VariableRegistry.setVariable>
   */
   public function setVariable(name: String, value: Dynamic): Void {
      variables.set(name, value);
   }

   /*
      Group: Custom option parsing methods
      
      Function: writerModuleOptions
         Module option writer used by <Optparse>.

         Stores options specified by command line options *-m*, *--module-options*.
   */
   static function writerModuleOptions(options: Dynamic, field: String, value: Dynamic) {
      var module = value[0].key;

      if(!options.modopts.exists(module))
         options.modopts.set(module, new Hash<String>());

      var opts = options.modopts.get(module);
      for(i in 1...value.length)
         opts.set(value[i].key, value[i].value);
   }
   
   /*
      Function: writerModuleHelp
         Module help option writer used by <Optparse>.

         Stores options specified by command line option *--module-help*.
   */
   static function writerModuleHelp(options: Dynamic, field: String, value: Array<{key: String, value: String}>) {
      for(module in value) {
         var help: ModuleHelpPars = {
            module: module.key,
            if_version: null,
            flash_version: 10
         };

         if(module.value != null) {
            var v_arr = module.value.split(";");

            if(v_arr.length > 1) {
               help.if_version = v_arr[0];
               help.flash_version = Std.parseInt(v_arr[1]);
            } else
               help.if_version = module.value;
         }

         options.modhelp.push(help);
      }
   }

   /*
      Group: main
      
      Function: main
         Application's main entry point.
   */
   public static function main() {
      new SamHaXe();
   }
}

