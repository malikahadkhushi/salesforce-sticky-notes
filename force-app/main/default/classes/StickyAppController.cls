public with sharing class StickyAppController {


    // Method to retrieve all notes
    @AuraEnabled
    public static List<Notes__c> getNotes(String objectId) {
        
        Id ownerId = UserInfo.getUserId();

        try {
            if (String.isNotBlank(objectId)) {
                // Query owned notes
                List<Notes__c> ownedNotes = [
                    SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c
                    FROM Notes__c
                    WHERE OwnerId = :ownerId AND ObjectId__c = :objectId
                    ORDER BY CreatedDate DESC
                ];
            
                // Query shared notes
                List<Notes__c> sharedNotes = [
                    SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c
                    FROM Notes__c
                    WHERE Id IN (
                        SELECT Note__c
                        FROM SharedNote__c
                        WHERE User__c = :ownerId
                    )
                    AND ObjectId__c = :objectId
                    ORDER BY CreatedDate DESC
                ];
            
                // Combine results and remove duplicates
                Set<Id> uniqueNoteIds = new Set<Id>();
                List<Notes__c> combinedNotes = new List<Notes__c>();
            
                for (Notes__c note : ownedNotes) {
                    if (!uniqueNoteIds.contains(note.Id)) {
                        uniqueNoteIds.add(note.Id);
                        combinedNotes.add(note);
                    }
                }
            
                for (Notes__c note : sharedNotes) {
                    if (!uniqueNoteIds.contains(note.Id)) {
                        uniqueNoteIds.add(note.Id);
                        combinedNotes.add(note);
                    }
                }

                return combinedNotes;


                //     List<Notes__c> notes = [
                //     SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c
                //     FROM Notes__c
                //     WHERE (OwnerId = :ownerId AND ObjectId__c = :objectId)
                //     AND Id IN (
                //         SELECT Note__c
                //         FROM SharedNote__c
                //         WHERE User__c = :ownerId
                //     )
                //     ORDER BY CreatedDate DESC
                // ];
                // return notes;
            
            } else {
                // Query owned notes
                List<Notes__c> ownedNotes = [
                    SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c
                    FROM Notes__c
                    WHERE OwnerId = :ownerId
                    ORDER BY CreatedDate DESC
                ];
            
                // Query shared notes
                List<Notes__c> sharedNotes = [
                    SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c
                    FROM Notes__c
                    WHERE Id IN (
                        SELECT Note__c
                        FROM SharedNote__c
                        WHERE User__c = :ownerId
                    )
                    ORDER BY CreatedDate DESC
                ];
            
                // Combine results and remove duplicates
                Set<Id> uniqueNoteIds = new Set<Id>();
                List<Notes__c> combinedNotes = new List<Notes__c>();
            
                for (Notes__c note : ownedNotes) {
                    if (!uniqueNoteIds.contains(note.Id)) {
                        uniqueNoteIds.add(note.Id);
                        combinedNotes.add(note);
                    }
                }
            
                for (Notes__c note : sharedNotes) {
                    if (!uniqueNoteIds.contains(note.Id)) {
                        uniqueNoteIds.add(note.Id);
                        combinedNotes.add(note);
                    }
                }
            
                return combinedNotes;
                
                // List<Notes__c> notes = [
                //     SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c
                //     FROM Notes__c
                //     WHERE (OwnerId = :ownerId)
                //     AND Id IN (
                //         SELECT Note__c
                //         FROM SharedNote__c
                //         WHERE User__c = :ownerId
                //     )
                //     ORDER BY CreatedDate DESC
                // ];
                // return notes;
            }
                      

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving notes: ' + e.getMessage());
        }
    }
    

    // Method to create a new note
    @AuraEnabled
    public static Notes__c createNote(String title, String content, String objectId) {
        try {
            Notes__c newNote = new Notes__c(
                Title__c = title,
                Content__c = content,
                ObjectId__c = objectId
            );
            insert newNote;
            return newNote;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating note: ' + e.getMessage());
        }
    }

    // Method to update an existing note
    @AuraEnabled
    public static Notes__c updateNote(Id Id, String title, String content, String objectId) {
        try {
            Notes__c noteToUpdate = [SELECT Id FROM Notes__c WHERE Id = :Id];
            noteToUpdate.Title__c = title;
            noteToUpdate.Content__c = content;
            noteToUpdate.ObjectId__c = objectId;
            update noteToUpdate;
            return noteToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating note: ' + e.getMessage());
        }
    }

    // Method to delete a note
    @AuraEnabled
    public static void deleteNote(Id Id) {
        try {
            Notes__c record= [SELECT Id FROM Notes__c WHERE Id = :Id];
            delete record;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting note: ' + e.getMessage());
        }
    }


    @AuraEnabled
    public static List<User> getUsers(){
        try {
        Id ownerId = UserInfo.getUserId();
            List<User> users = [SELECT Id, Name, Email FROM User WHERE IsActive = TRUE AND Id != :ownerId];
            return users;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<SharedNote__c> sharedNotes(List<Map<String, Object>> data) {
        try {

            List<SharedNote__c> sharedNotesToInsert = new List<SharedNote__c>();
    
            for (Map<String, Object> record : data) {
                SharedNote__c sharedNote = new SharedNote__c();
                sharedNote.Note__c = (String)record.get('Note'); 
                sharedNote.User__c = (String)record.get('User');
                sharedNotesToInsert.add(sharedNote);
            }
    
            insert sharedNotesToInsert;
                return sharedNotesToInsert;
        } catch (Exception e) {
            // Log the error and throw an AuraHandledException for the client
            System.debug('Error while sharing notes: ' + e.getMessage());
            throw new AuraHandledException('Error while sharing notes: ' + e.getMessage());
        }
    }
    
    
}
