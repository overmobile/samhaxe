/*
   Title: Helpers.hx
      Miscallenous helper functions collected into a class.
*/

import Xml;
import format.swf.Data;

/*
   Anonymous: XmlNN
      Tuple for xml namespace and local name
*/
typedef XmlNN = {
   /*
      Variable: ns
         Namespace
   */
   ns : String,
   /*
      Variable: ln
         Local name
   */
   ln : String
}

enum HashIdSymCheckResult {
   HISCR_NewIdSymExistsId(id: Int, coll_id: Int);
   HISCR_NewIdSymNotExists(id: Int);
   HISCR_FoundIdSymExistsOk(id: Int);
   HISCR_FoundIdSymExistsId(id: Int, coll_id: Int);
   HISCR_FoundIdSymNotExists(id: Int);
}

enum HashIdSymWarnResult {
   HISWR_SkipOk;
   HISWR_DataFound(id: Int);
   HISWR_New(id: Int);
   HISWR_NewOnlyData(id: Int);
}

/*
   Class: Helpers
      Helper class with static functions used across the entire application.
*/
class Helpers {

   /*
      Group: text helper methods

      Function: expandTabs
         Replaces all tabs with 3 spaces.

      Parameters:
         s - the string to alter

      Returns:
         The altered string
   */
   public static function expandtabs(s : String) : String {
      return StringTools.replace(s, "\t", "   ");
   }

   /*
      Function: tabbed
         Adds three spaces to the beginning of each line of the parameter string.

      Parameters:
         s - the string to pad

      Returns:
         The padded string
   */
   public static function tabbed(s : String) : String {
      var b = new StringBuf();

      var first = true;
      for (part in s.split("\n")) {
         if (first)
            first = false;
         else
            b.add("\n");

         b.add("   ");
         b.add(part);
      }

      return b.toString();
   }

   /*
      Function: onelined
         Removes newlines from the string.

      Parameters:
         s - the string to be transformed

      Returns:
         The cleaned string
   */
   inline public static function onelined(s : String) : String {
      return ~/[\n\r]/.replace(s, "");
   }
 
   /*
      Group: Namespaced Xml helper methods

      Function: getXmlNN
         Returns the namespace and localname of an Xml.Element

      Parameters:
         x - the Xml element

      Returns:
         The corresponding <XmlNN> tuple
   */
   public static function getXmlNN(x : Xml) : XmlNN {
      if (x.nodeType != Xml.Element)
         throw "Bad Xml type, expected Element";

      var nn = x.nodeName.split(':');
      if (nn.length == 2)
         return {
            ns : nn[0],
            ln : nn[1]
         }
      else
         return {
            ns : '',
            ln : nn[0]
         }
   }
   
   /*
      Function: elementsLocalNamed
         Returns all elements with the given localname.

      Parameters:
         lname - the local name

      Returns:
         The requested elements.
   */
   public static function elementsLocalNamed(x : Xml, lname : String) {
      var l = new List();
      for (e in x.elements()) {
         if (getXmlNN(e).ln == lname)
            l.add(e);
      }
      return l;
   }
 
   /*
      Function: elementsNamespaced
         Returns all elements in a given namespace

      Parameters:
         ns - the namespace

      Returns:
         The requested elements.
   */
   public static function elementsNamespaced(x : Xml, ns : String) { 
      var l = new List();
      for (e in x.elements()) {
         if (getXmlNN(e).ns == ns)
            l.add(e);
      }
      return l;
   }

   /*
      Group: Import modules helper methods

      Function: generateClass
         Generates a class definition with the given superclass.

      Parameters:
         as3Reg - the AS3 registry instance
         className - the class name to generate
         superClassName - the name of the superclass to derive from
   */
   public static function generateClass(as3Reg: AS3Registry, className: String, superClassName: String) { 
      var ctx = as3Reg.getContext();
      var cl = ctx.beginClass(className, true);
      cl.superclass = ctx.type(superClassName);
      ctx.endSubClass();
   }

   /*
      Function: getIdForHashSymbolCheck
         Returns a character ID for the given data hash and tag type
         and checks the availability of the given symbol class.

      Parameters:
         md5 - the MD5 sum of the asset
         tagId - the SWF tag ID
         idReg - the IdRegistry instance
         symbolReg - the SymbolRegistry instance
         symbol - the AS3 class name

      Returns:
         The character ID, wrapped in HashIdSymCheckResult.
   */
   public static function getIdForHashSymbolCheck(
      md5: String,
      tagId: Int,
      idReg: IdRegistry,
      ?symbolReg: SymbolRegistry,
      ?symbol: String
   ): HashIdSymCheckResult {
      if (symbolReg != null && symbol == null) 
         throw "Error: pass a symbol if you passed the symbolRegistry";

      switch (idReg.getIdForHash(md5, tagId)) {
         case BILR_New(id):
            if (symbolReg == null)
               return HISCR_NewIdSymNotExists(id);
            if (symbolReg.symbolExists(symbol))
               return HISCR_NewIdSymExistsId(id, symbolReg.getSymbolCid(symbol));
            
            return HISCR_NewIdSymNotExists(id);
         
         case BILR_Found(id):
            if (symbolReg == null)
               return HISCR_FoundIdSymNotExists(id);

            if (symbolReg.symbolExists(symbol)) {
               var other_id = symbolReg.getSymbolCid(symbol);
               
               if (other_id == id)
                  return HISCR_FoundIdSymExistsOk(id);
               
               return HISCR_FoundIdSymExistsId(id, other_id);
            }
            /*
            else {
               var old_sym = symbolReg.getCidSymbol(id);
               if (old_sym != null)
                  // New symbol name requires a full import with new cid
                  return HISCR_NewIdSymNotExists(idReg.getNewId());
            }
            */

            return HISCR_FoundIdSymNotExists(id);
      }
   }

   public static function getIdForHashSymbolWarn(
      hash_base: String,
      tagId: Int,
      idReg: IdRegistry,
      ?symReg: SymbolRegistry,
      ?symbol: String,
      ?storeSymbol = true
   ): HashIdSymWarnResult { 
      
      var hashIdRes = getIdForHashSymbolCheck(
         haxe.Md5.encode(hash_base),
         tagId,
         idReg,
         symReg,
         symbol
      );

      return switch (hashIdRes) {
      case HISCR_NewIdSymExistsId(id, coll_id), HISCR_FoundIdSymExistsId(id, coll_id):
         // The symbol we wanted is already taken by some other resource

         // TODO: use logger service
         neko.Lib.print("[WARN] symbol '" + symbol + "' already defined for CID " + coll_id + ", not registering new symbol!\n");

         // Symbol is not redefined, but insert the data anyway
         HISWR_NewOnlyData(id);

      case HISCR_NewIdSymNotExists(id), HISCR_FoundIdSymNotExists(id):
         if (symReg != null)
            symReg.addSymbol(id, symbol, storeSymbol);

         switch (hashIdRes) {
         case HISCR_NewIdSymNotExists(a):
            HISWR_New(id);
         default:
            // TODO: use logger service
            if (symbol != null)
               neko.Lib.print("[INFO] found matching data for '" + symbol + "' (CID " + id + "), adding symbol only.\n");
            else
               neko.Lib.print("[INFO] found matching data (CID " + id + "), skipping import.\n");
            
            // May still need to generate class def
            HISWR_DataFound(id);
         }

      case HISCR_FoundIdSymExistsOk(id):
         // Same data and symbol
         // TODO: use logger service
         neko.Lib.print("[INFO] found matching data & symbol for '" + symbol + "' (CID " + id + "), skipping import.\n");

         HISWR_SkipOk;
      }
   }

   /*
      Group: Version string related functions

      Function: stripBugfixVersion
         Removes the bugfix version from version string if present.

      Parameters:
         version - the version string

      Returns:
         The stripped version string.
   */
   public static function stripBugfixVersion(version: String): String {
      var v_arr = version.split(".");

      return if(v_arr.length == 3)
         v_arr[0] + "." + v_arr[1];
      else
         version;
   }

}
