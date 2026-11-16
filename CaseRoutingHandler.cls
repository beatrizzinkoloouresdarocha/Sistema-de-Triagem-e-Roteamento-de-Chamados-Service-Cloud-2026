public with sharing class CaseRoutingHandler {

    // Método BEFORE INSERT: define prioridade e fila antes de salvar no banco
    public static void routeCases(List<Case> newCases) {
        Set<Id> accountIds = new Set<Id>();
        for (Case c : newCases) {
            if (c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }

        // Busca o Nível de Suporte das Contas vinculadas
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Support_Level__c FROM Account WHERE Id IN :accountIds]
        );

        // Busca os IDs das Filas (Queues)
        Map<String, Id> queueMap = new Map<String, Id>();
        for (Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN ('Atendimento_VIP', 'Suporte_Nivel_1')]) {
            queueMap.put(g.DeveloperName, g.Id);
        }

        for (Case c : newCases) {
            Boolean isVip = false;
            if (c.AccountId != null && accountMap.containsKey(c.AccountId)) {
                isVip = (accountMap.get(c.AccountId).Support_Level__c == 'Ouro');
            }

            Boolean hasUrgentKeyword = false;
            if (String.isNotBlank(c.Subject)) {
                String subjectLower = c.Subject.toLowerCase();
                hasUrgentKeyword = subjectLower.contains('urgente') || subjectLower.contains('erro');
            }

            // Aplica a regra de negócio
            if (isVip || hasUrgentKeyword) {
                c.Priority = 'High';
                if (queueMap.containsKey('Atendimento_VIP')) {
                    c.OwnerId = queueMap.get('Atendimento_VIP');
                }
            } else {
                if (queueMap.containsKey('Suporte_Nivel_1')) {
                    c.OwnerId = queueMap.get('Suporte_Nivel_1');
                }
            }
        }
    }

    // Método AFTER INSERT: cria a tarefa de SLA para casos de alta prioridade
    public static void createFollowUpTasks(List<Case> newCases) {
        List<Task> tasksToInsert = new List<Task>();

        for (Case c : newCases) {
            if (c.Priority == 'High') {
                Task t = new Task();
                t.Subject = 'Retorno Urgente SLA (2h): ' + c.Subject;
                t.WhatId = c.Id; // Vincula ao Caso
                t.Status = 'Not Started';
                t.Priority = 'High';
                t.ActivityDate = Date.today();
                tasksToInsert.add(t);
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
}