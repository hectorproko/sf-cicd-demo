@isTest
private class ExpenseServiceTest {

    @isTest
    static void flagsExpenseOverThreshold() {
        Expense__c exp = new Expense__c(Amount__c = 600, Category__c = 'Travel');
        Test.startTest();
        insert exp;
        Test.stopTest();
        exp = [SELECT Requires_Approval__c FROM Expense__c WHERE Id = :exp.Id];
        Assert.isTrue(exp.Requires_Approval__c, 'Expenses over 500 should require approval');
    }

    @isTest
    static void doesNotFlagAtThreshold() {
        Expense__c exp = new Expense__c(Amount__c = 500, Category__c = 'Meals');
        insert exp;
        exp = [SELECT Requires_Approval__c FROM Expense__c WHERE Id = :exp.Id];
        Assert.isFalse(exp.Requires_Approval__c, 'Exactly 500 should not require approval');
    }

    @isTest
    static void reflagsOnUpdate() {
        Expense__c exp = new Expense__c(Amount__c = 100, Category__c = 'Equipment');
        insert exp;
        exp.Amount__c = 700;
        update exp;
        exp = [SELECT Requires_Approval__c FROM Expense__c WHERE Id = :exp.Id];
        Assert.isTrue(exp.Requires_Approval__c, 'Raising amount over 500 should flag on update');
    }

    @isTest
    static void handlesBulkInsert() {
        List<Expense__c> expenses = new List<Expense__c>();
        for (Integer i = 0; i < 200; i++) {
            expenses.add(new Expense__c(Amount__c = Math.mod(i, 2) == 0 ? 50 : 900));
        }
        Test.startTest();
        insert expenses;
        Test.stopTest();
        Integer flagged = [SELECT COUNT() FROM Expense__c WHERE Requires_Approval__c = true];
        Assert.areEqual(100, flagged, 'Half of 200 records should be flagged');
    }
}