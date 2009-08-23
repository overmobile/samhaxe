/*
   Title: ModuleInterface.hx
*/
import format.swf.Data;

/*
   Interface: ModuleService_1_0
      Interface provided for import modules by SamHaXe version 1.0.
*/
interface ModuleService_1_0 {
   /*
      Function: getFlashVersion
         Returns the flash version used by the asset library.

      Returns:
         The flash version.
   */
   public function getFlashVersion() : Int;

   /*
      Function: getIdRegistry
         Returns the <IdRegistry> instance.

      Returns:
         The <IdRegistry> instance.
   */
   public function getIdRegistry(): IdRegistry;

   /*
      Function: getSymbolRegistry
         Returns the <SymbolRegistry> instance for actual frame.

      Returns:
         The actual <SymbolRegistry> instance.
   */
   public function getSymbolRegistry(): SymbolRegistry;

   /*
      Function: getAS3Registry
         Returns the <AS3Registry> instance for actual frame.

      Returns:
         The actual <AS3Registry> instance.
   */
   public function getAS3Registry(): AS3Registry;
   
   /*
      Function: getDependencyRegistry
         Returns the <DependencyRegistry> instance.

      Returns:
         The <DependencyRegistry> instance.
   */
   public function getDependencyRegistry(): DependencyRegistry;
   
   /*
      Function: getVariableRegistry
         Returns the <VariableRegistry> instance.

      Returns:
         The <VariableRegistry> instance.
   */
   public function getVariableRegistry(): VariableRegistry;

   /*
      Function: runImport
         Imports resources described by the asset parameter.

         This function enables import modules to invoke foreign import modules
         by passing them the appropriate XML node.

      Parameters:
         asset - the XML node describing the asset to be imported.

      Returns:
         The array of SWF tags imported by the foreign module.
   */
   public function runImport(asset : NsFastXml): Array<SWFTag>;
}

