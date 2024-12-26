@isTest
public class ColorsTest {
    @isTest
    static void testGetColors() {
        // Query existing metadata records
        List<Color_Code__mdt> metadataRecords = [
            SELECT Color_Code__c, Color_Name__c 
            FROM Color_Code__mdt
        ];
        
        // Ensure that metadata records exist
        System.assert(metadataRecords.size() > 0, 'There should be at least one Color_Code__mdt record in the org.');

        // Call the method
        Test.startTest();
        List<Map<String, String>> colors = Color.getColors();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, colors, 'Colors list should not be null');
        System.assertEquals(metadataRecords.size(), colors.size(), 'Colors list size should match the number of metadata records.');

        // Verify the first color (if metadata exists)
        if (!colors.isEmpty()) {
            Map<String, String> firstColor = colors[0];
            System.assertNotEquals(null, firstColor.get('name'), 'First color name should not be null');
            System.assertNotEquals(null, firstColor.get('code'), 'First color code should not be null');
        }
    }
}
