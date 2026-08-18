trigger AccountRiskEventTrigger on Account_Risk_Event__e (after insert) {
    AccountRiskEventService.processEvents(Trigger.new);
}