/*
   Title: SamHaXeModule.hx
      Import module proxy.
*/
import format.swf.Data;

/*
   Typedef: ImportFunction
      Prototype of an import function.

      > NsFastXml -> Hash<String> -> Array<SWFTag>
*/
typedef ImportFunction = NsFastXml -> Hash<String> -> Array<SWFTag>;

/*
   Typedef: CheckFunction
      Prototype of an asset check function.

      Used for validating the structure of the asset XML node
      to be processed by the import function.

      > NsFastXml -> Void
*/
typedef CheckFunction  = NsFastXml -> Void;

// TODO: What's this Ron? :)
typedef RegisterFunction  = String -> Dynamic -> Void;

/*
   Typedef: HelpFunction
      Prototype of a help function.

      Returns the long help message provided by an import module.

      > Void -> String
*/
typedef HelpFunction  = Void -> String;

/*
   Class: SamHaXeModule
      Wrapper class around an import module.
*/
class SamHaXeModule {
   /*
      Group: Interface independent exports

      Variable: INTERFACES
         Name of array variable of supported interface versions. 
   */
   public inline static var INTERFACES = "interfaces";

   /*
      Variable: DESCRIPTION
         Name of string variable of short module description.
   */
   public inline static var DESCRIPTION = "description";

   /*
      Variable: INIT_MODULE
         Name of module initializatoon function.
   */
   public inline static var INIT_MODULE = "initModule";

   /*
      Variable:
         Name of interface initialization function.
   */
   public inline static var INIT_INTERFACE = "initInterface";

   /*
      Group: Interface dependent exports

      Variable: IMPORT_FUN_1_0
         Name of asset importing function in module interface version 1.0.
   */
   public inline static var IMPORT_FUN_1_0 = "import";

   /*
      Variable: CHECK_FUN_1_0
         Name of XML node checking function in module interface version 1.0.
   */
   public inline static var CHECK_FUN_1_0 = "check";
   public inline static var REGISTER_FUN_1_0 = "register";
   
   /*
      Variable: HELP_FUN_1_0
         Name of module help function in module interface version 1.0.
   */
   public inline static var HELP_FUN_1_0 = "help";

   /*
      Group: genclass attribute constants

      Variable: GENCLASS_FALSE
         Don't generate neither symbol class nor AS3 class stub.         
   */
   public inline static var GENCLASS_FALSE = "false";

   /*
      Variable: GENCLASS_SYMBOL_ONLY
         Generate only symbol class.
   */
   public inline static var GENCLASS_SYMBOL_ONLY = "symbolOnly";

   /*
      Variable: GENCLASS_SYMBOL_AND_CLASS
         Generate symbol class and AS3 class stub.
   */
   public inline static var GENCLASS_SYMBOL_AND_CLASS = "symbolAndClass";

   /*
      Group: Interface independent members and methods
   */
   public var name(default, null): String;
   public var uri(default, null): String;
   public var initialized(default, null): Bool;
   var module: neko.vm.Module;
   var exports: Hash<Dynamic>;

   /*
      Constructor: new
         Constructor

      Parameters:
         module_name - the short name of the module (equals the module file name without the .n extension)
         uri - the unique namespace uri of the module, without the interface version selector anchor
   */
   public function new(module_name: String, uri: String) {
      this.name = module_name;
      this.uri = uri;

      var ldr = neko.vm.Loader.local();
      try {
         module = ldr.loadModule(name);
      } catch(e: Dynamic) {
         throw new ModuleException("Error loading module '" + name + "'");
      }

      exports = module.getExports();

      var check_exports = [INTERFACES, DESCRIPTION, INIT_MODULE, INIT_INTERFACE];
      for(ex in check_exports)
         if(!exports.exists(ex))
            throw "Error loading module '" + name + "': '" + ex + "' export not found!";

      initialized = false;
   }

   /*
      Function: isCompatibleVersion
         Checks if the given module interface version is compatible with the requested.
         The interface version is expected to be in Major.Minor.Bugfix format,
         while the requested version may omit the bugfix or the minor and bugfix
         levels - in these cases the corrseponding levels are not checked.
         All checked levels have to match in order the test to pass.

      Parameters:
         version - the interface version in Major.Minor.Bugfix format
         req_version - the interface version requested by the resource xml file, in Major[.Minor[.Bugfix]] format

      Returns:
         the result of the compatibility test

   */
   public function isCompatibleVersion(version: String, req_version: String): Bool {
      var v = version.split(".");
      var rv = if(req_version.length > 0) req_version.split(".") else [];
      var n = if(v.length < rv.length) v.length else rv.length;

      var i = 0;
      while(i < n && v[i] == rv[i])
         i++;

      return i == n;
   }

   /*
      Function: getCompatibleVersion
         Looks up the module interface of highest possible version constrained by
         the required version and the interface versions supported by SamHaXe.

         Omitting version levels means that getCompatibleVersion is free to choose any version for the given levels.
      
      Parameters:
         supported_versions - interface versions supported by SamHaXe in Major[.Minor[.Bugfix]] format
         required_version - the interface version requested by the resource xml file, in Major[.Minor[.Bugfix]] format

      Returns:
         the chosen version string         
   */
   public function getCompatibleVersion(supported_versions: Array<String>, required_version: String): String {
      var module_versions: Array<String> = exports.get(INTERFACES);
      
      // Descending sort module and supported versions
      module_versions.sort(function(a,b) return -Reflect.compare(a,b));
      supported_versions.sort(function(a,b) return -Reflect.compare(a,b));

      var version: String = null;
      
      for(module_v in module_versions) {
         if(isCompatibleVersion(module_v, required_version)) {
            for(supported_v in supported_versions)
               if(isCompatibleVersion(supported_v, required_version) && isCompatibleVersion(module_v, supported_v)) {
                  version = module_v;
                  break;
               }
            
            if(version != null)
               break;
         }
      }

      return version;
   }

   /*
      Function: init
         Initializes the module by selecting and exposing a compatible module interface.
         See <getCompatibleVersion> for interface selection details.

      Parameters:
         supported_versions - interface versions supported by SamHaXe in Major[.Minor[.Bugfix]] format
         required_version - the interface version requested by the resource xml file, in Major[.Minor[.Bugfix]] format
         moduleServices - function to request the Module Services interface for a given interface version. See <SamHaXe::getModuleService>.
   */
   public function init(supported_versions: Array<String>, required_version: String, moduleServices : String -> Dynamic) {
      var init_module_fn = exports.get(INIT_MODULE);
      if(!init_module_fn())
         throw new ModuleException("Error initializing module '" + name + "': init failed!");

      var if_version = getCompatibleVersion(supported_versions, required_version);
      if(if_version == null)
         throw new ModuleException("Error initializing module '" + name + "': no matching interface version was found!");

      // Acquire appropriate interface
      var init_interface_fn = exports.get(INIT_INTERFACE);

      init_interface_fn(if_version, moduleServices(if_version));
      exports = module.getExports();

      exposeInterface(if_version);

      initialized = true;
   }

   // TODO: What's this Ron? :)
   function exposeInterface(if_version : String) {
   }
   
   /*
      Function: getDescription
      
      Returns:
         the short description of the module
   */
   public function getDescription(): String {
      return exports.get(DESCRIPTION);
   }

   /*
      Function: getImportFunction

      Returns:
         the import function for handling xml fragments
   */
   public function getImportFunction(): ImportFunction {
      if(!exports.exists(IMPORT_FUN_1_0))
         throw new ModuleException(name + ": Import function not exported: '" + IMPORT_FUN_1_0 + "'");

      return exports.get(IMPORT_FUN_1_0);
   }
   
   /*
      Function: getCheckFunction

      Returns:
         the check function for validating xml fragments,
         or null if such function is not exported
   */
   public function getCheckFunction(): CheckFunction {
      return exports.get(CHECK_FUN_1_0);
   }
   
   
   /*
      Function: getHelpFunction

      Returns:
         the help function for displaying module-specific help message,
         or null if such function is not exported
   */

   public function getHelpFunction(): HelpFunction {
      return exports.get(HELP_FUN_1_0);
   }
}
