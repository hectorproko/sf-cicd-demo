trigger ExpenseTrigger on Expense__c (before insert, before update) {
    ExpenseService.flagForApproval(Trigger.new);
}