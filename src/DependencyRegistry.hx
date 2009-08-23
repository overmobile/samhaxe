/*
   Title: DependencyRegistry.hx
*/

/*
   Interface: DependencyRegistry
      
      Keeps track of file dependencies of the actual asset library.
*/
interface DependencyRegistry {
   /*
      Function: addFilePath

         Adds a new file to the dependency list.

      Parameters:

         p - the path of file to be added to the list.
   */
   function addFilePath(p: String): Void;
}

