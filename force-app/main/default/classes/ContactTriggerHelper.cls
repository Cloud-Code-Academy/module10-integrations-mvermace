public with sharing class ContactTriggerHelper {
    
    
    
    // Called from BEFORE_INSERT, sets Id (random) if null
    public static void processInsertingContacts(List<Contact> triggerList) {
        
        for (Contact cont : triggerList) {
            if (cont.DummyJSON_Id__c == null) {
                cont.DummyJSON_Id__c = Math.round(Math.random()*100).toString();
            }
        }
        
    }

    public static void processInsertedContacts(List<Contact> insertedContacts) {

        List<Contact> IsLessThanEqualTo100 = new List<Contact>();
        List<Contact> IsMoreThan100 = new List<Contact>();

        for (Contact cont : insertedContacts) {
            if (Integer.valueOf(cont.DummyJSON_Id__c) <= 100) {
                IsLessThanEqualTo100.add(cont);
            } else if (Integer.valueOf(cont.DummyJSON_Id__c) > 100) {
                IsMoreThan100.add(cont);
            }
        }

        for (Contact cont : IsLessThanEqualTo100) {
            DummyJSONCallout.getDummyJSONUserFromId(cont.DummyJSON_Id__c);
        }

        for (Contact cont : IsMoreThan100) {
            DummyJSONCallout.postCreateDummyJSONUser(cont.Id);
        }

    }



}