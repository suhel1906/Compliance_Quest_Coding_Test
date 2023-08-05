/**
 * @description       : Account Creation and SF Task
 * @author            : Suhel Tiwari
 * @group             : 
 * @last modified on  : 08-05-2023
 * @LastModifiedBy    : Suhel Tiwari
**/
public with sharing class AccountTriggerHandler {
    /**
    * @description this method is used to call the trigger events method
    * @author Suhel Tiwari | 08-05-2023 
    **/
    public void run() {
        if(Trigger.isBefore && Trigger.isInsert) {
            beforeInsert(Trigger.new);
        }
        else if(Trigger.isAfter && Trigger.isInsert) {
            afterInsert(Trigger.new);
        }
        else if(Trigger.isBefore && Trigger.isUpdate) {
            Map<Id, Account> oldMap = (Map<Id, Account>) Trigger.oldMap;
            beforeUpdate(Trigger.new, oldMap);
        }
        else if(Trigger.isAfter && Trigger.isUpdate) {
            Map<Id, Account> newMap = (Map<Id, Account>) Trigger.newMap;
            afterUpdate(newMap);
        }
    }
    /**
    * @description execute on before insert to validate any ctive account not to be inserted
    * @author Suhel Tiwari | 08-05-2023 
    * @param newAccountList new account list from trigger.new
    **/
    void beforeInsert(List<Account> newAccountList) {
        for(Account eachAccount : newAccountList) {
            if(eachAccount.Active__c) {
                eachAccount.addError('Active account not be created');
            }
        }
    }
    /**
    * @description execute on after insert to create associated task of account
    * @author Suhel Tiwari | 08-05-2023
    * @param newAccountList new account list from trigger.new
    **/
    void afterInsert(List<Account> newAccountList) {
        try {
            List<Task> associatedAccTask = new List<Task>();
            for(Account eachAccount : newAccountList) {
                associatedAccTask.add(new Task(Subject = 'Review Account- '+eachAccount.AccountNumber, ActivityDate = Date.today().addDays(7), OwnerId = eachAccount.OwnerId, WhatId = eachAccount.Id, Status = 'Not Started'));
            }
            if(!associatedAccTask.isEmpty() && Schema.SObjectType.Task.isCreateable()) {
                insert associatedAccTask;
            }
        } catch(Exception e) {
            System.debug('Message>>' + e.getMessage() + ' at line>>'+e.getLineNumber());
            throw e;
        }
    }
    /**
    * @description execute on before update which prevent account should not be activated those have not permission set assigned and if assigned then complete the associated task
    * @author ChangeMeIn@UserSettingsUnder.SFDoc | 08-05-2023 
    * @param newAccountList new account list from trigger.new
    * @param oldAccountMap old account map from trigger.oldmap
    * @param newAccountMap new account map from trigger.newMap
    **/
    void beforeUpdate(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        try {
            //get assigned permission set of current user
            List<PermissionSetAssignment> getPermissionSet = new List<PermissionSetAssignment>();
            getPermissionSet = [SELECT id FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSet.Name = 'CQ_Account_Admin' WITH SECURITY_ENFORCED LIMIT 1];
            //Prevent account from activate if permission set not assigned
            for(Account eachAccount : newAccountList) {
                if(eachAccount.Active__c && oldAccountMap.get(eachAccount.Id).Active__c != eachAccount.Active__c && getPermissionSet.size() == 0) {
                    if(getPermissionSet.size() == 0) {
                        eachAccount.addError('Insufficient privilege to activate the account');
                    }
                }
            }
        } catch(Exception e) {
            System.debug('Message>>' + e.getMessage() + ' at line>>'+e.getLineNumber());
            throw e;
        }
    }
    void afterUpdate(Map<Id, Account> newAccountMap) {
        try {
            List<Task> completedTaskList = new List<Task>();
            for(Task eachTask : [SELECT WhatId, Description FROM Task WHERE WhatId IN :newAccountMap.keySet() AND Status != 'Completed' WITH SECURITY_ENFORCED LIMIT 10000]) {
                completedTaskList.add(new Task(Status = 'Completed', Id = eachTask.Id));
            }
            if(!completedTaskList.isEmpty() && Schema.SObjectType.Task.isUpdateable()) {
                update completedTaskList;
            }
        } catch(Exception e) {
            System.debug(e.getMessage());
        }
    }
}