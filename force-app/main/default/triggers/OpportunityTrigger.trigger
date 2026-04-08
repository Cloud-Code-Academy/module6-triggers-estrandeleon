trigger OpportunityTrigger on Opportunity (before update, before delete) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        OpportunityTriggerHandler.handleBeforeUpdate(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isDelete) {
        OpportunityTriggerHandler.handleBeforeDelete(Trigger.old);
    }
}
