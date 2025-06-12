public with sharing class updateNewContactsQueueableMinus100 implements Queueable  {
    
    private Map<Id,Contact> contacts;

    public updateNewContactsQueueableMinus100() {
        this.contacts = contacts;
    }
    
    public static void enqueueJob() {                     
        // Get 10 accounts with Next Step populated
        Map<Id,Account> acctsToUpdate = new Map<Id,Account>([SELECT Id, Name, Next_Step__c FROM Account WHERE Next_Step__c != null WITH USER_MODE LIMIT 10]);
        // If there are any accounts, queue the job using System.enqueueJob
        if (acctsToUpdate.size() > 0) {
            ID jobId = System.enqueueJob(new NextStepQueueable(acctsToUpdate)); 
        }
    }

    /*
     * Update/Uncomment the template code to create a method
     * Method to execute the queueable job
     */
    public void execute(QueueableContext context) {
        
        // Get the accounts from the member variable
        List<Account> acctsToUpdate = new List<Account>(accounts.values()); 
        for (Account acc : acctsToUpdate) {
            removeNextStep(acc);                        // Remove the Next Step using the helper method
        }
        update acctsToUpdate;                           // Update the accounts
        
        // Get the opportunities related to the accounts
        List<Opportunity> oppsToUpdate = [SELECT Id, Name, NextStep FROM Opportunity WHERE AccountId IN :accounts.keySet()];
        for (Opportunity opp : oppsToUpdate) {
            removeNextStep(opp);                        // Remove the Next Step using the helper method
        }
        update oppsToUpdate;                            // Update the opportunities
        
        enqueueJob();                                   // Call the enqueueJob method to queue another job to process more records.
    }

    // Helper method to remove the Next Step
    // Overloaded method to accept an opportunity
    private static void removeNextStep(Opportunity opp) {
        opp.NextStep = null;
    }

    // Helper method to remove the Next Step
    // Overloaded method to accept an account
    private static void removeNextStep(Account acc) {
        acc.Next_Step__c = null;
    }
}
}