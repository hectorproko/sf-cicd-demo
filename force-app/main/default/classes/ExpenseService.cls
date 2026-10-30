public with sharing class ExpenseService {
    public static final Decimal APPROVAL_THRESHOLD = 1000;

    public static void flagForApproval(List<Expense__c> expenses) {
        for (Expense__c exp : expenses) {
            exp.Requires_Approval__c =
                exp.Amount__c != null && exp.Amount__c > APPROVAL_THRESHOLD;
        }
    }
}