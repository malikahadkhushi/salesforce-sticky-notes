public with sharing class StickyAppController {


    // Method to retrieve all notes
    @AuraEnabled
    public static List<Notes__c> getNotes(String objectId) {
        
        Id ownerId = UserInfo.getUserId();

        try {
            if (String.isNotBlank(objectId)) {
                // Query owned notes
                List<Notes__c> ownedNotes = [
                    SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c,Color_Code__c
                    FROM Notes__c
                    WHERE OwnerId = :ownerId AND ObjectId__c = :objectId
                    ORDER BY CreatedDate DESC
                ];
            
                // Query shared notes
                List<Notes__c> sharedNotes = [
                    SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c,Color_Code__c
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
                    SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c,Color_Code__c
                    FROM Notes__c
                    WHERE OwnerId = :ownerId
                    ORDER BY CreatedDate DESC
                ];
            
                // Query shared notes
                List<Notes__c> sharedNotes = [
                    SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c,Color_Code__c
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
    public static Notes__c createNote(String title, String content, String objectId,String code) {
        try {
            Notes__c newNote = new Notes__c(
                Title__c = title,
                Content__c = content,
                ObjectId__c = objectId,
                Color_Code__c = code
            );
            insert newNote;
            return newNote;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating note: ' + e.getMessage());
        }
    }

    // Method to update an existing note
    @AuraEnabled
    public static Notes__c updateNote(Id Id, String title, String content, String objectId, String code) {
        try {
            Notes__c noteToUpdate = [SELECT Id FROM Notes__c WHERE Id = :Id];
            noteToUpdate.Title__c = title;
            noteToUpdate.Content__c = content;
            noteToUpdate.ObjectId__c = objectId;
            noteToUpdate.Color_Code__c = code ;
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
            Id ownerId = UserInfo.getUserId();
            SharedNote__c sharedNote = [SELECT Id FROM SharedNote__c WHERE Note__c = :Id AND User__c = :ownerId];
            Notes__c record= [SELECT Id FROM Notes__c WHERE Id = :Id];
            if(sharedNote != null){
                delete sharedNote;
            }else{
                delete record;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting note: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<User> getUsers(){
        try {
        Id ownerId = UserInfo.getUserId();

        Map<Id, String> profileToLicenseMap = new Map<Id, String>();

        List<Profile> profiles = [
            SELECT Id,Name, UserLicense.Name 
            FROM Profile
        ];

        for (Profile profile :profiles) { 
            profileToLicenseMap.put(profile.Id, profile.UserLicense.Name);
        }

        List<User> users = [
            SELECT Id, Name, Email, ProfileId 
            FROM User 
            WHERE IsActive = TRUE 
            AND Id != :ownerId
        ];

        List<User> filterUsers = new List<User>();

        // Attach license information to each user
        for (User user : users) {
            String license = profileToLicenseMap.get(user.ProfileId);
            if(license == 'Salesforce' || license == 'Salesforce Platform' || license == 'Salesforce integration'){
                filterUsers.add(user);
            }
        }
        System.debug('filterUsers'+filterUsers);
         return filterUsers;
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
            throw new AuraHandledException('Error while sharing notes: ' + e.getMessage());
        }
    }   
}
