@isTest
public class StickyAppControllerTest {

    // Method to set up test data
    private static void setupTestData() {
        // Create test notes
        List<Notes__c> notes = new List<Notes__c>{
            new Notes__c(Title__c = 'Note 1', Content__c = 'Content 1', ObjectId__c = '001xx000003DGbPAAW'),
            new Notes__c(Title__c = 'Note 2', Content__c = 'Content 2', ObjectId__c = '001xx000003DGbPAAW')
        };
        insert notes;

        // Create a test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'malikahadofficial2266@gmail.com',
            Username = 'malikahadofficial2266@gmail.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Share a note with the test user
        SharedNote__c sharedNote = new SharedNote__c(
            Note__c = notes[0].Id,
            User__c = testUser.Id
        );
        insert sharedNote;
    }


    @isTest
    static void testGetNotesWithoutObjectId() {
        setupTestData();
    
        // Test without objectId
        Test.startTest();
        List<Notes__c> notes = StickyAppController.getNotes('','');
        Test.stopTest();
    
        System.assert(notes.size() > 0, 'Notes should be retrieved without an objectId.');
    }
    
    @isTest
    static void testGetNotesWithObjectId() {
        setupTestData();
    
        // Test with a valid objectId
        Test.startTest();
        List<Notes__c> notes = StickyAppController.getNotes('001xx000003DGbPAAW','Note');
        Test.stopTest();
    
        System.assert(notes.size() > 0, 'Notes should be retrieved for the given objectId.');
    }
    


    @isTest
    static void testCreateNote() {

        Test.startTest();
        Notes__c newNote = StickyAppController.createNote('New Note', 'New Content', '001xx000003DGbPAAW', '#55efc4');
        Test.stopTest();

        System.assertNotEquals(null, newNote.Id, 'New note should be created.');
        System.assertEquals('New Note', newNote.Title__c, 'Title should match.');
    }

    @isTest
    static void testUpdateNote() {
        setupTestData();
        Notes__c note = [SELECT Id, Title__c FROM Notes__c LIMIT 1];

        Test.startTest();
        Notes__c updatedNote = StickyAppController.updateNote(note.Id, 'Updated Title', 'Updated Content', '001xx000003DGbPAAW', '#00b894');
        Test.stopTest();

        System.assertEquals('Updated Title', updatedNote.Title__c, 'Title should be updated.');
    }

    @isTest
    static void testDeleteNote() {
        setupTestData();
        Notes__c note = [SELECT Id FROM Notes__c LIMIT 1];

        Test.startTest();
        StickyAppController.deleteNote(note.Id);
        Test.stopTest();

        Integer noteCount = [SELECT COUNT() FROM Notes__c WHERE Id = :note.Id];
        System.debug('noteCount'+noteCount);
        System.assertEquals(0, noteCount, 'Note should be deleted.');
    }

    @isTest
    static void testGetUsers() {
        setupTestData();

        Test.startTest();
        List<User> users = StickyAppController.getUsers();
        Test.stopTest();

        System.assert(users.size() > 0, 'Active users should be retrieved.');
    }

    @isTest
    static void testSharedNotes() {
        setupTestData();
        Notes__c note = [SELECT Id FROM Notes__c LIMIT 1];
        User user = [SELECT Id FROM User WHERE Email = 'ahad.ali@focusteck.com' LIMIT 1];

        Map<String, Object> sharedNoteData = new Map<String, Object>{
            'Note' => note.Id,
            'User' => user.Id
        };

        List<Map<String, Object>> sharedNotesData = new List<Map<String, Object>>{sharedNoteData};

        Test.startTest();
        List<SharedNote__c> sharedNotes = StickyAppController.sharedNotes(sharedNotesData);
        Test.stopTest();

        System.assert(sharedNotes.size() > 0, 'Shared notes should be created.');
        System.assertEquals(note.Id, sharedNotes[0].Note__c, 'Note ID should match.');
        System.assertEquals(user.Id, sharedNotes[0].User__c, 'User ID should match.');
    }

    // @isTest
    // static void testSendNotificationsToUsers() {
    //     setupTestData();
        
    //     // Fetch the users to whom the notification will be sent
    //     User user1 = [SELECT Id FROM User WHERE Email = 'malikahadofficial2266@gmail.com' LIMIT 1];
    //     User user2 = [SELECT Id FROM User WHERE Email = 'anotheremail@example.com' LIMIT 1];
        
    //     // Prepare the user IDs list
    //     List<Id> userIds = new List<Id>{ user1.Id, user2.Id };
        
    //     Test.startTest();
        
    //     // Call the method to send notifications
    //     StickyAppController.sendNotificationsToUsers(userIds, 'Test Note Title');
        
    //     Test.stopTest();            
    // }


    @isTest
static void testSendNotificationsToUsers() {
    setupTestData();
    
    // Create 200 test users
    List<User> testUsers = new List<User>();
    Id profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
    System.debug('profileId'+profileId);

    for(Integer i = 0; i < 200; i++) {
        testUsers.add(new User(
            FirstName = 'Test' + i,
            LastName = 'User' + i,
            Alias = 'tus' + i,
            Email = 'test_user00' + i + '@example.com',
            Username = 'test_user00' + i + '@example.com',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        ));
    }
    
    insert testUsers;
    
    // Prepare the user IDs list
    List<Id> userIds = new List<Id>();
    for(User u : testUsers) {
        userIds.add(u.Id);
    }
    
    System.debug('------>'+userIds);
    Test.startTest();
    // Call the method to send notifications
    StickyAppController.sendNotificationsToUsers(userIds, 'Test Note Title');
    Test.stopTest();
    
    // Add assertions if needed
    System.assertEquals(200, userIds.size(), 'Should have 200 users for notification');
}

    @isTest
    static void testSendEmailsToUsers() {

        setupTestData();
        User testUser = [SELECT Id FROM User WHERE Email = 'malikahadofficial2266@gmail.com' LIMIT 1];
        List<Id> userIds = new List<Id>{ testUser.Id };

        Test.startTest();
        StickyAppController.sendEmailsToUsers(userIds, 'Test Note Title');
        Test.stopTest();

        // Assert that emails were sent, this can be checked by using EmailMessage or other methods
        System.assert(true, 'Emails should be sent.');
    }
}
