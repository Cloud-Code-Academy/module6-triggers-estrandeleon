public with sharing class OpportunityTriggerHandler {
    private static final Decimal MINIMUM_AMOUNT = 5000;
    private static final String AMOUNT_ERROR_MESSAGE = 'Opportunity amount must be greater than 5000';
    private static final String DELETE_ERROR_MESSAGE = 'Cannot delete closed opportunity for a banking account that is won';
    private static final String BANKING_INDUSTRY = 'Banking';
    private static final String CLOSED_WON_STAGE = 'Closed Won';
    private static final String CEO_TITLE = 'CEO';

    // Applies all update-time business rules in a single pass.
    public static void handleBeforeUpdate(List<Opportunity> newOpportunities) {
        Map<Id, Id> accountIdToCeoContactId = getCeoContactByAccountId(newOpportunities);

        for (Opportunity opportunityRecord : newOpportunities) {
            validateAmount(opportunityRecord);
            applyPrimaryContact(opportunityRecord, accountIdToCeoContactId);
        }
    }

    // Blocks deletes that violate the banking closed-won rule.
    public static void handleBeforeDelete(List<Opportunity> oldOpportunities) {
        Set<Id> accountIds = new Set<Id>();

        for (Opportunity opportunityRecord : oldOpportunities) {
            if (opportunityRecord.AccountId != null) {
                accountIds.add(opportunityRecord.AccountId);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        Set<Id> bankingAccountIds = getBankingAccountIds(accountIds);

        for (Opportunity opportunityRecord : oldOpportunities) {
            if (opportunityRecord.StageName == CLOSED_WON_STAGE &&
                bankingAccountIds.contains(opportunityRecord.AccountId)) {
                opportunityRecord.addError(DELETE_ERROR_MESSAGE);
            }
        }
    }

    private static void validateAmount(Opportunity opportunityRecord) {
        if (opportunityRecord.Amount != null && opportunityRecord.Amount <= MINIMUM_AMOUNT) {
            opportunityRecord.Amount.addError(AMOUNT_ERROR_MESSAGE);
        }
    }

    private static void applyPrimaryContact(
        Opportunity opportunityRecord,
        Map<Id, Id> accountIdToCeoContactId
    ) {
        if (opportunityRecord.AccountId != null &&
            accountIdToCeoContactId.containsKey(opportunityRecord.AccountId)) {
            opportunityRecord.Primary_Contact__c = accountIdToCeoContactId.get(opportunityRecord.AccountId);
        }
    }

    // Queries one CEO contact per account and returns it as a lookup map.
    private static Map<Id, Id> getCeoContactByAccountId(List<Opportunity> opportunities) {
        Set<Id> accountIds = new Set<Id>();

        for (Opportunity opportunityRecord : opportunities) {
            if (opportunityRecord.AccountId != null) {
                accountIds.add(opportunityRecord.AccountId);
            }
        }

        Map<Id, Id> accountIdToCeoContactId = new Map<Id, Id>();
        if (accountIds.isEmpty()) {
            return accountIdToCeoContactId;
        }

        for (Contact contactRecord : [
            SELECT Id, AccountId
            FROM Contact
            WHERE AccountId IN :accountIds
            AND Title = :CEO_TITLE
            ORDER BY CreatedDate ASC
        ]) {
            if (!accountIdToCeoContactId.containsKey(contactRecord.AccountId)) {
                accountIdToCeoContactId.put(contactRecord.AccountId, contactRecord.Id);
            }
        }

        return accountIdToCeoContactId;
    }

    private static Set<Id> getBankingAccountIds(Set<Id> accountIds) {
        Set<Id> bankingAccountIds = new Set<Id>();

        for (Account accountRecord : [
            SELECT Id
            FROM Account
            WHERE Id IN :accountIds
            AND Industry = :BANKING_INDUSTRY
        ]) {
            bankingAccountIds.add(accountRecord.Id);
        }

        return bankingAccountIds;
    }
}
