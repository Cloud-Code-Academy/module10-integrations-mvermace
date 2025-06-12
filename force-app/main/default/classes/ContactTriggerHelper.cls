public with sharing class ContactTriggerHelper {
    
    // Called from BEFORE_INSERT, sets Id (random) if null
    public static void processInsertedContacts(List<Contact> triggerList) {

        System.debug('Before DummyJSON_Id__c is set: ' + JSON.serializePretty(triggerList));
        
        for (Contact cont : triggerList) {
            if (cont.DummyJSON_Id__c == null) {
                cont.DummyJSON_Id__c = Math.round(Math.random()*100).toString();
            }
        }
        System.debug('After DummyJSON_Id__c is set: ' + JSON.serializePretty(triggerList));
    }

    public static void updateNewContacts(List<Contact> triggerList) {
        
        System.debug('Record(s) made it to AFTER_INSERT: ' + JSON.serializePretty(triggerList));

        List<Contact> contSubset = new List<Contact>();
        for (Contact cont : triggerList) {
            if ( Integer.valueOf(cont.DummyJSON_Id__c) <= 100 ) {
                contSubset.add(cont);
            }
        }

        System.debug('Contacts with Ids < 100: ' + JSON.serializePretty(contSubset));    
        
        for (Contact cont : contSubset) {
            System.debug('cont.DummyJSON_Id__c: ' + String.valueOf(cont.DummyJSON_Id__c));
            DummyJSONCallout.getDummyJSONUserFromId(cont.DummyJSON_Id__c);
        }
    
    
    }
        
        // update triggerList;

        // List<Contact> contID_LE100 = new List<Contact>();
        
        // for (Contact cont : triggerList) {
        //     if (Integer.valueOf(cont.DummyJSON_Id__c) <= 100) {
        //         contID_LE100.add(cont);
        //     }
        // }

        // for (Contact cont : contID_LE100) {
        //     DummyJSONCallout.getDummyJSONUserFromId(cont.DummyJSON_Id__c);
        // }

        // System.debug('triggerOld: ' + JSON.serializePretty(triggerList));
        // System.debug('contId_LE100: ' + JSON.serializePretty(contID_LE100));
        
    

    

}