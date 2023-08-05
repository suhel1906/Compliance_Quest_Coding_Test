/**
 * @description       : Account Creation and SF Task
 * @author            : Suhel Tiwari
 * @group             : 
 * @last modified on  : 08-05-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class TaskTriggerHandler {
    /**
    * @description call trigger events method
    * @author ChangeMeIn@UserSettingsUnder.SFDoc | 08-05-2023 
    **/
    public void run() {
        if(Trigger.isUpdate && Trigger.isBefore) {
            Map<Id, Task> oldTask = (Map<Id, Task>) Trigger.oldMap;
            beforeUpdate(Trigger.new, oldTask);
        }
        else if(Trigger.isUpdate && Trigger.isAfter) {
            Map<Id, Task> oldTask = (Map<Id, Task>) Trigger.oldMap;
            afterUpdate(Trigger.new, oldTask);
        }
    }
    /**
    * @description prevent user to make task complete who does not have permission set
    * @author ChangeMeIn@UserSettingsUnder.SFDoc | 08-05-2023 
    * @param newTaskList new task list from Trigger.new
    * @param oldTaskMap old task map from trigger.oldMap
    **/
    void beforeUpdate(List<Task> newTaskList, Map<Id, Task> oldTaskMap) {
        try {
            List<PermissionSetAssignment> getPermissionSet = new List<PermissionSetAssignment>();
            getPermissionSet = [SELECT id FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSet.Name = 'CQ_Account_Admin' WITH SECURITY_ENFORCED LIMIT 1];
            for(Task eachTask : newTaskList) {
                if(eachTask.Status == 'Completed' && eachTask.Status != oldTaskMap.get(eachTask.Id).Status && getPermissionSet.size() == 0) {
                    eachTask.addError('Insufficient privilege to complete the task');
                }
            }
        } catch(Exception e) {
            System.debug(e.getMessage());
            throw e;
        }
    }
    /**
    * @description Activate respective account when task is completed
    * @author Suhel Tiwari | 08-05-2023 
    * @param newTaskList new task list from Trigger.new
    * @param oldTaskMap old task map from trigger.oldMap
    **/
    void afterUpdate(List<Task> newTaskList, Map<Id, Task> oldTaskMap) {
        try {
            Map<Id, Account> accountMap = new Map<Id, Account>();
            for(Task eachTask : newTaskList) {
                if(eachTask.Status == 'Completed' && oldTaskMap.get(eachTask.Id).Status != eachTask.Status && eachTask.WhatId != null && eachTask.WhatId.getSObjectType().getDescribe().getName() == 'Account') {
                    accountMap.put(eachTask.WhatId, new Account(Id = eachTask.WhatId, Active__c = true, Description = eachTask.Description));
                }
            }
            if(!accountMap.isEmpty() && Schema.SObjectType.Account.isUpdateable()) {
                update accountMap.values();
            }
        } catch(Exception e) {
            System.debug(e.getMessage());
            throw e;
        }
    }
}