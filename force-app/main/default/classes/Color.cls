// public with sharing class Color {
//     public Color() {}

//     // get All colors
//     @AuraEnabled
//     public static List<Colors__c> getColors(){
//         try {
//             List<Colors__c> colors = [SELECT Name from Colors__c];
//             return colors;
//         } catch (Exception e) {
//             throw new AuraHandledException(e.getMessage());
//         }
//     }
// }

public with sharing class Color {
    @AuraEnabled
    public static List<Map<String, String>> getColors() {
        try {
            // Query Custom Metadata records
            List<	Color_Code__mdt> metadataRecords = [
                SELECT Color_Code__c, Color_Name__c 
                FROM Color_Code__mdt
            ];

            // Prepare a list of maps to return color data
            List<Map<String, String>> colors = new List<Map<String, String>>();
            for (Color_Code__mdt record : metadataRecords) {
                if (record.Color_Code__c != null && record.Color_Name__c != null) {
                    Map<String, String> colorMap = new Map<String, String>{
                        'name' => record.Color_Name__c,
                        'code' => record.Color_Code__c
                    };
                    colors.add(colorMap);
                }
            }

            return colors;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
