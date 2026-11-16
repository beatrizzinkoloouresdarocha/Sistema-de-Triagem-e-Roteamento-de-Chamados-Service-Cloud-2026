trigger CaseTrigger on Case (before insert, after insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        CaseRoutingHandler.routeCases(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        CaseRoutingHandler.createFollowUpTasks(Trigger.new);
    }
}