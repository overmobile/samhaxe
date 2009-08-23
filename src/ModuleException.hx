/*
   Title: ModuleException.hx
*/

/*
   Class: ModuleException
      Exception class thrown by import modules.
*/
class ModuleException {
   /*
      Variable: msg
         Exception message.
   */
   var msg: String;

   /*
      Constructor: new
         
      Parameters:
         msg - the exception message
   */
   public function new(msg: String) {
      this.msg = msg;
   }

   /*
      Function: toString
         Converts the exception into a string.

      Returns:
         The string representation of the exception.
   */
   public function toString(): String {
      return msg;
   }
} 
