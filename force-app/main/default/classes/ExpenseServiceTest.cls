@isTest
private class ExpenseServiceTest {

    private static final Decimal T = ExpenseService.APPROVAL_THRESHOLD;

    private static User userWithExpenseAccess() {
        Id psId = [SELECT Id FROM PermissionSet WHERE Name = 'Expense_Access'].Id;
        Id me = UserInfo.getUserId();
        if ([SELECT COUNT() FROM PermissionSetAssignment
             WHERE AssigneeId = :me AND PermissionSetId = :psId] == 0) {
            insert new PermissionSetAssignment(AssigneeId = me, PermissionSetId = psId);
        }
        return new User(Id = me);
    }

    @isTest
    static void thresholdMatchesBusinessRule() {
        Assert.areEqual(1000, ExpenseService.APPROVAL_THRESHOLD,
            'Business rule: expenses above $1000 require approval');
    }

    @isTest
    static void flagsExpenseOverThreshold() {
        System.runAs(userWithExpenseAccess()) {
            Expense__c exp = new Expense__c(Amount__c = T + 1, Category__c = 'Travel');
            Test.startTest();
            insert exp;
            Test.stopTest();
            exp = [SELECT Requires_Approval__c FROM Expense__c WHERE Id = :exp.Id];
            Assert.isTrue(exp.Requires_Approval__c, 'Amount above threshold should require approval');
        }
    }

    @isTest
    static void doesNotFlagAtThreshold() {
        System.runAs(userWithExpenseAccess()) {
            Expense__c exp = new Expense__c(Amount__c = T, Category__c = 'Meals');
            insert exp;
            exp = [SELECT Requires_Approval__c FROM Expense__c WHERE Id = :exp.Id];
            Assert.isFalse(exp.Requires_Approval__c, 'Amount exactly at threshold should not require approval');
        }
    }

    @isTest
    static void reflagsOnUpdate() {
        System.runAs(userWithExpenseAccess()) {
            Expense__c exp = new Expense__c(Amount__c = T - 1, Category__c = 'Equipment');
            insert exp;
            exp.Amount__c = T + 1;
            update exp;
            exp = [SELECT Requires_Approval__c FROM Expense__c WHERE Id = :exp.Id];
            Assert.isTrue(exp.Requires_Approval__c, 'Raising amount above threshold should flag on update');
        }
    }

    @isTest
    static void handlesBulkInsert() {
        System.runAs(userWithExpenseAccess()) {
            List<Expense__c> expenses = new List<Expense__c>();
            for (Integer i = 0; i < 200; i++) {
                expenses.add(new Expense__c(Amount__c = Math.mod(i, 2) == 0 ? 50 : T + 1));
            }
            Test.startTest();
            insert expenses;
            Test.stopTest();
            Integer flagged = [SELECT COUNT() FROM Expense__c WHERE Requires_Approval__c = true];
            Assert.areEqual(100, flagged, 'Half of 200 records should be flagged');
        }
    }
}