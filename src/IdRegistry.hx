/*
   Title: IdRegistry.hx
*/

enum BytesIdLookupResult {
   BILR_Found(id : Int);
   BILR_New(id : Int);
}

/*
   Interface: IdRegistry
      Keeps track of character IDs requested by import functions.
*/
interface IdRegistry {
   /*
      Function: idExists
         Checks whether a given character ID has already been defined.

      Parameters:
         id - the character ID

      Returns:
         true if the ID has already been defined, false otherwise.
   */
   public function idExists(id: Int): Bool;

   /*
      Function: getNewId
         Queries a new characterd ID guaranteed to be unique.

      Returns:
         The new character ID.
   */
   public function getNewId(): Int;

   /*
      Function: getIdForHash
         Checks and returns if a character ID was already assigned for the
         given hashed data of the given tag type, or a new unique id if
         not found.

         Note: the md5 hash should include all relevant data bytes

      Parameters:
         md5 - the MD5 hash of data bytes
         tagId - format.swf.TagId of resource type, to avoid Binary vs. Sound collisions etc.

      Returns:
         The character ID, wrapped in BytesIdLookupResult according to
         whether the requested hash was found or not.

   */
   public function getIdForHash(md5: String, tagId: Int): BytesIdLookupResult;
}

