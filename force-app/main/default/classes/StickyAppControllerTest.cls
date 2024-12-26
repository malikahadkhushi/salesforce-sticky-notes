@isTest
public class StickyAppControllerTest {

    // Method to set up test data
    private static void setupTestData() {
        // Create test notes
        List<Notes__c> notes = new List<Notes__c>{
            new Notes__c(Title__c = 'Note 1', Content__c = 'Content 1', ObjectId__c = '001xx000003DGbPAAW', Color_Code__c = '#ffeaa7'),
            new Notes__c(Title__c = 'Note 2', Content__c = 'Content 2', ObjectId__c = '001xx000003DGbPAAW', Color_Code__c = '#fdcb6e')
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
        List<Notes__c> notes = StickyAppController.getNotes('');
        Test.stopTest();
    
        System.assert(notes.size() > 0, 'Notes should be retrieved without an objectId.');
    }
    
    @isTest
    static void testGetNotesWithObjectId() {
        setupTestData();
    
        // Test with a valid objectId
        Test.startTest();
        List<Notes__c> notes = StickyAppController.getNotes('001xx000003DGbPAAW');
        Test.stopTest();
    
        System.assert(notes.size() > 0, 'Notes should be retrieved for the given objectId.');
        System.assertEquals(2, notes.size(), 'There should be exactly 2 notes retrieved for the objectId.');
    }
    


    @isTest
    static void testCreateNote() {

        Test.startTest();
        Notes__c newNote = StickyAppController.createNote('New Note', 'New Content', '001xx000003DGbPAAW', '#55efc4');
        Test.stopTest();

        System.assertNotEquals(null, newNote.Id, 'New note should be created.');
        System.assertEquals('New Note', newNote.Title__c, 'Title should match.');
        System.assertEquals('#55efc4', newNote.Color_Code__c, 'Color code should match.');
    }

    @isTest
    static void testUpdateNote() {
        setupTestData();
        Notes__c note = [SELECT Id, Title__c FROM Notes__c LIMIT 1];

        Test.startTest();
        Notes__c updatedNote = StickyAppController.updateNote(note.Id, 'Updated Title', 'Updated Content', '001xx000003DGbPAAW', '#00b894');
        Test.stopTest();

        System.assertEquals('Updated Title', updatedNote.Title__c, 'Title should be updated.');
        System.assertEquals('#00b894', updatedNote.Color_Code__c, 'Color code should be updated.');
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
}
