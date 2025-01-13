public with sharing class StickyAppController {


    @AuraEnabled
    public static List<Notes__c> getNotes(String objectId, String text) {
        Id ownerId = UserInfo.getUserId();
    
    
        try {
            // Base query conditions
            String searchCondition = '';
            if (String.isNotBlank(text)) {
                searchCondition = ' AND (Title__c LIKE \'%' + String.escapeSingleQuotes(text) + '%\')';
            }
    
            if (String.isNotBlank(objectId)) {
                // Query owned notes
                List<Notes__c> ownedNotes = Database.query(
                    'SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c,Color_Code__c ' +
                    'FROM Notes__c ' +
                    'WHERE OwnerId = :ownerId ' + searchCondition +
                    ' ORDER BY CreatedDate DESC'
                );
    
                // Query shared notes
                List<Notes__c> sharedNotes = Database.query(
                    'SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c,Color_Code__c ' +
                    'FROM Notes__c ' +
                    'WHERE Id IN (SELECT Note__c FROM SharedNote__c WHERE User__c = :ownerId) ' +
                    'AND ObjectId__c = :objectId ' + searchCondition +
                    ' ORDER BY CreatedDate DESC'
                );
    
                // Combine results and remove duplicates
                return combineNotes(ownedNotes, sharedNotes);
            } else {
                // Query owned notes
                List<Notes__c> ownedNotes = Database.query(
                    'SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c,Color_Code__c ' +
                    'FROM Notes__c ' +
                    'WHERE OwnerId = :ownerId AND ObjectId__c = null ' + searchCondition +
                    ' ORDER BY CreatedDate DESC'
                );
    
                // Query shared notes
                List<Notes__c> sharedNotes = Database.query(
                    'SELECT Id, Title__c, Content__c, OwnerId, CreatedDate, ObjectId__c,Color_Code__c ' +
                    'FROM Notes__c ' +
                    'WHERE Id IN (SELECT Note__c FROM SharedNote__c WHERE User__c = :ownerId) ' +
                    searchCondition +
                    ' ORDER BY CreatedDate DESC'
                );
    
                // Combine results and remove duplicates
                return combineNotes(ownedNotes, sharedNotes);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving notes: ' + e.getMessage());
        }
    }
    
    // Helper method to combine notes and remove duplicates
    private static List<Notes__c> combineNotes(List<Notes__c> ownedNotes, List<Notes__c> sharedNotes) {
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
            noteToUpdate.Color_Code__c = code;
            update noteToUpdate;

            // // Publish Platform Event
            // NoteUpdateEvent__e event = new NoteUpdateEvent__e(
            //     NoteId__c = noteToUpdate.Id,
            //     Title__c = noteToUpdate.Title__c,
            //     Content__c = noteToUpdate.Content__c,
            //     ObjectId__c = noteToUpdate.ObjectId__c,
            //     ColorCode__c = noteToUpdate.Color_Code__c
            // );

            // EventBus.publish(event);
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
            List<SharedNote__c> sharedNotes = [SELECT Id FROM SharedNote__c WHERE Note__c = :Id AND User__c = :ownerId];
            Notes__c record= [SELECT Id FROM Notes__c WHERE Id = :Id];
            if(sharedNotes.size() > 0){
                delete sharedNotes;
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

    @AuraEnabled
    public static void sendNotificationsToUsers(List<Id> userIds, String noteTitle) {
        try {
            // Get the Custom Notification Type Developer Name
            CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'customnotification'];
            String senderName = Userinfo.getName();
            String senderId = Userinfo.getUserId();
    
                    List<Messaging.CustomNotification> notifications = new List<Messaging.CustomNotification>();

            // Loop through each user ID in the list and send a notification
            for (Id userId : userIds) {

                Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                customNotificationObj.setBody(senderName + ' shared a note "' + noteTitle + '" with you!');
                customNotificationObj.setTitle('Note shared with you');
                customNotificationObj.setTargetId(userId); // Send to each user individually
                customNotificationObj.setNotificationTypeId(cnType.id);
                customNotificationObj.setSenderId(senderId);
                
                // Send the notification to the user
                customNotificationObj.send(new Set<String> {userId});
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error while sharing notes: ' + e.getMessage());
        }
    }
    
    

    @AuraEnabled
    public static void sendEmailsToUsers(List<Id> userIds, String noteTitle) {
        // Get the current user's name
        String currentUserName = UserInfo.getName();
    
        List<User> users = [SELECT Id, Email FROM User WHERE Id IN :userIds];
    
        // Create a list to hold the email messages
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    
        // Loop through the users and prepare the emails
        for (User user : users) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ user.Email });
            email.setSubject('Note is Shared with you');
            email.setPlainTextBody(currentUserName + ' shared the note "' + noteTitle + '" with you.');
            emails.add(email);
        }
    
        // Send the emails
        Messaging.sendEmail(emails);
    }
}
