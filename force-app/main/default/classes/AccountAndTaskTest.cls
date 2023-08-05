/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-05-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class AccountAndTaskTest {
    @isTest
    static void testProcess(){
        Account firstAccount = new Account();
        firstAccount.Name = 'Test Account';
        firstAccount.AccountNumber = 'CA89114421';
        insert firstAccount;
        String taskSubj = 'Review Account- '+firstAccount.AccountNumber;
        List<Task> getTask = new List<Task>();
        getTask = [SELECT Id FROM Task WHERE Subject = :taskSubj];
        Assert.isFalse(getTask.isEmpty(), 'No task found');

        firstAccount.Active__c = true;
        update firstAccount;
        List<Task> getTask1 = new List<Task>();
        getTask1 = [SELECT Id FROM Task WHERE Subject = :taskSubj AND Subject = 'Completed'];
        Assert.isFalse(getTask.isEmpty(), 'Task not completed');
    }
}