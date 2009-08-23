/*
   Title: Config.hx
*/

import format.swf.Data;
import SamHaXeModule;

/*
   Anonymous: ModuleInfo
      Container for storing information about loaded modules
*/
typedef ModuleInfo = {
   /*
      Variable: version
         Version string of the module.
   */
   var version: String;

   /*
      Variable: module
         Module instance
   */
   var module: SamHaXeModule;
}

/*
   Class: Config
      Configuration and module management class.
*/
class Config {
   var uri2name: Hash<String>;
   var name2uri: Hash<String>;
   var version2module: Hash<ModuleInfo>;

   var supported_versions: Array<String>;
   var moduleServices : String -> Dynamic;

   /*
      Constructor: new
         Constructor.
      
      Parameters:
         supported_versions - The array of modules interface version strings SamHaXe supports.
         moduleServices - The function which returns the appropriate module interface for a version string.
   */
   public function new(supported_versions: Array<String>, moduleServices : String -> Dynamic) {
      uri2name = new Hash<String>();
      name2uri = new Hash<String>();
      version2module = new Hash<ModuleInfo>();

      this.supported_versions = supported_versions;
      this.moduleServices = moduleServices;
   }

   /*
      Function: load
         Loads configuration file.

      Parameters:
         config_file - The name and path of config file.
   */
   public function load(config_file: String) {
      var xml_data: String;
      try {
         xml_data = neko.io.File.getContent(config_file);
      } catch(e: Dynamic) {
         throw "Unable to open "+config_file+"!";
      }
      
      var conf = new haxe.xml.Fast(Xml.parse(xml_data).firstElement());

      var modpath = conf.node.modules.att.path;
      if(modpath.charAt(modpath.length - 1) != "/")
         modpath += "/";
      
      var loader = neko.vm.Loader.local();
      loader.addPath(modpath);
      loader.addPath(modpath + "native/");

      for(module in conf.node.modules.nodes.module)
         addModule(module.att.name, module.att.uri);
   }

   function splitUri(uri: String): Array<String> {
      var i = uri.lastIndexOf("#");

      return if(i == -1)
         [uri, ""]
      else
         [uri.substr(0, i), uri.substr(i + 1)];
   }

   /*
      Function: getModule
         Returns the module instance for the given namespace URI.
         If the given module doesn't loaded yet or loaded but with different version,
         then creates a new istance.

      Parameters:
         uri - The namespace URI

      Returns:
         The module instance.
   */
   public function getModule(uri: String): SamHaXeModule {
      var uri_comp = splitUri(uri);
      var base_uri = uri_comp[0];
      var req_version = uri_comp[1];

      if(req_version != "") {
         if(version2module.exists(uri))
            return version2module.get(uri).module;

         var name = uri2name.get(base_uri);

         if(name == null)
            throw "No module found for URI: " + base_uri;

         var module = new SamHaXeModule(name, base_uri);
         var version = module.getCompatibleVersion(supported_versions, req_version);
         if(version == null)
            throw "Requested version ("+req_version+") for module '"+name+"' is not supported!";

         version2module.set(uri, {
            version: version,
            module: module
         });

         return module;

      } else {
         if(uri2name.exists(uri)) {
            var module = new SamHaXeModule(uri2name.get(uri), uri);
            version2module.set(uri, {
               version: "",
               module: module
            });
            return module;
         } else
            throw "No module found for URI: " + uri;
      }
   }

   /*
      Function: getModuleUri
         Returns the namespace URI for a given module name.

      Parameters:
         module_name - The name of the module.

      Returns:
         The namespace URI.
   */
   public function getModuleUri(module_name: String): String {
      return name2uri.get(module_name);
   }

   function addModule(module_name: String, uri: String) {
      if(!uri2name.exists(uri)) {
         uri2name.set(uri,module_name);
         name2uri.set(module_name, uri);
      } else
         throw "A module("+uri2name.get(uri)+") already exists for URI: " + uri;
   }

   /*
      Function: initModule
         Initializes the module for the given namespace URI.

      Parameters:
         uri - The namespace URI for the module.

   */
   public function initModule(uri: String) {
      if(version2module.exists(uri)) {
         var mi = version2module.get(uri);
         mi.module.init(supported_versions, mi.version, moduleServices);
      }
   }

   /*
      Function: initAllModules
         Initializes all module instances requested so far.
   */
   public function initAllModules() {
      for(mi in version2module) {
         if(!mi.module.initialized)
            mi.module.init(supported_versions, mi.version, moduleServices);
      }
   }
   
   /*
      Function: modules
         Returns an iterator over module URIs.

      Returns:
         An iterator over module URIs.
   */
   public function modules(): Iterator<String> {
      return uri2name.iterator();
   }
}

