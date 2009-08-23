/*
   Title: VariableRegistry.hx
*/

/*
   Interface: VariableRegistry
      Keeps track of variables shared between import modules.
*/
interface VariableRegistry {
   /*
      Function: getVariable
         Retrieves the vaule of a variable.

      Parameters:
         name - the name of the variable

      Returns:
         The value of the variable.
   */
   function getVariable(name: String): Dynamic;

   /*
      Function: setVariable
         Sets the vaule of a variable.

      Parameters:
         name - the name of the variable
         value - the new value
   */
   function setVariable(name: String, value: Dynamic): Void;
}
