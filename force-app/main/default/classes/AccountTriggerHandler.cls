public with sharing class AccountTriggerHandler {
    private static final String PROSPECT_TYPE = 'Prospect';
    private static final String HOT_RATING = 'Hot';
    private static final String DEFAULT_CONTACT_LAST_NAME = 'DefaultContact';
    private static final String DEFAULT_CONTACT_EMAIL = 'default@email.com';

    // Applies all field defaults before the records are committed.
    public static void handleBeforeInsert(List<Account> newAccounts) {
        for (Account accountRecord : newAccounts) {
            applyDefaultType(accountRecord);
            copyShippingAddressToBilling(accountRecord);
            applyHotRating(accountRecord);
        }
    }

    // Creates related contacts after Account ids are available.
    public static void handleAfterInsert(List<Account> newAccounts) {
        List<Contact> contactsToInsert = buildDefaultContacts(newAccounts);

        if (!contactsToInsert.isEmpty()) {
            insert contactsToInsert;
        }
    }

    private static void applyDefaultType(Account accountRecord) {
        if (String.isBlank(accountRecord.Type)) {
            accountRecord.Type = PROSPECT_TYPE;
        }
    }

    // Copies the full address only when at least one shipping field is populated.
    private static void copyShippingAddressToBilling(Account accountRecord) {
        if (!hasShippingAddressValue(accountRecord)) {
            return;
        }

        accountRecord.BillingStreet = accountRecord.ShippingStreet;
        accountRecord.BillingCity = accountRecord.ShippingCity;
        accountRecord.BillingState = accountRecord.ShippingState;
        accountRecord.BillingPostalCode = accountRecord.ShippingPostalCode;
        accountRecord.BillingCountry = accountRecord.ShippingCountry;
    }

    private static void applyHotRating(Account accountRecord) {
        if (hasValue(accountRecord.Phone) &&
            hasValue(accountRecord.Website) &&
            hasValue(accountRecord.Fax)) {
            accountRecord.Rating = HOT_RATING;
        }
    }

    // Builds all child contacts first so we can use a single DML statement.
    private static List<Contact> buildDefaultContacts(List<Account> newAccounts) {
        List<Contact> contactsToInsert = new List<Contact>();

        for (Account accountRecord : newAccounts) {
            contactsToInsert.add(new Contact(
                AccountId = accountRecord.Id,
                LastName = DEFAULT_CONTACT_LAST_NAME,
                Email = DEFAULT_CONTACT_EMAIL
            ));
        }

        return contactsToInsert;
    }

    private static Boolean hasShippingAddressValue(Account accountRecord) {
        return hasValue(accountRecord.ShippingStreet) ||
            hasValue(accountRecord.ShippingCity) ||
            hasValue(accountRecord.ShippingState) ||
            hasValue(accountRecord.ShippingPostalCode) ||
            hasValue(accountRecord.ShippingCountry);
    }

    private static Boolean hasValue(String value) {
        return !String.isBlank(value);
    }
}
