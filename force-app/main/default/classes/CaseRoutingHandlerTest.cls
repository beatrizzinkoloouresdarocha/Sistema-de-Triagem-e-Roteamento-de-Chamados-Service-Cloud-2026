@isTest
private class CaseRoutingHandlerTest {

    @TestSetup
    static void setupData() {
        // Cria Contas de teste
        Account vipAcc = new Account(Name = 'Empresa VIP Ltda', Support_Level__c = 'Ouro');
        Account stdAcc = new Account(Name = 'Empresa Padrão SA', Support_Level__c = 'Basico');
        insert new List<Account>{ vipAcc, stdAcc };
    }

    @isTest
    static void testVipCaseRouting() {
        Account vipAcc = [SELECT Id FROM Account WHERE Name = 'Empresa VIP Ltda' LIMIT 1];
        
        Case vipCase = new Case(
            AccountId = vipAcc.Id,
            Subject = 'Dúvida sobre fatura',
            Origin = 'Web'
        );

        Test.startTest();
        insert vipCase;
        Test.stopTest();

        // Verifica se a prioridade virou High
        Case insertedCase = [SELECT Priority FROM Case WHERE Id = :vipCase.Id];
        System.assertEquals('High', insertedCase.Priority, 'Caso VIP deveria ter prioridade High');

        // Verifica se a Tarefa de acompanhamento foi criada
        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE WhatId = :vipCase.Id];
        System.assertEquals(1, tasks.size(), 'Deveria ter sido criada 1 tarefa de SLA');
    }

    @isTest
    static void testStandardCaseRouting() {
        Account stdAcc = [SELECT Id FROM Account WHERE Name = 'Empresa Padrão SA' LIMIT 1];
        
        Case stdCase = new Case(
            AccountId = stdAcc.Id,
            Subject = 'Solicitação de cadastro',
            Origin = 'Phone'
        );

        Test.startTest();
        insert stdCase;
        Test.stopTest();

        Case insertedCase = [SELECT Priority FROM Case WHERE Id = :stdCase.Id];
        System.assertNotEquals('High', insertedCase.Priority, 'Caso comum não deveria ter prioridade High');
    }
}