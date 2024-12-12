public with sharing class StickyAppController {


    // Method to retrieve all notes
    @AuraEnabled
    public static List<Notes__c> getNotes(String objectId) {
        
        Id ownerId = UserInfo.getUserId();
        try {
            // Check if objectId is provided
            if (String.isNotBlank(objectId)) {
                // Query with both ownerId and objectId filters
                return [SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c 
                        FROM Notes__c 
                        WHERE OwnerId = :ownerId AND ObjectId__c = :objectId
                        ORDER BY CreatedDate DESC];
            } else {
                // Query with only ownerId filter
                return [SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c 
                        FROM Notes__c 
                        WHERE OwnerId = :ownerId
                        ORDER BY CreatedDate DESC];
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
}
