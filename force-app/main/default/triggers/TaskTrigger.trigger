/**
 * @description       : Task Trigger
 * @author            : Suhel Tiwari
 * @group             : 
 * @last modified on  : 08-05-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger TaskTrigger on Task (before update, after update) {
  (new TaskTriggerHandler()).run();
}