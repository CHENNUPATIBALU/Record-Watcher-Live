trigger RecordWatcherEventTrigger on Record_Watcher__e (after insert) {
    
    List<Record_Watcher__e> recordWatcherList = Trigger.New;
    if(!recordWatcherList.isEmpty()){
        String formattedObjApiName = recordWatcherList[0].sObjectName__c.replace('_','');
        String key = 'RW'+formattedObjApiName+recordWatcherList[0].Record_Id__c;
        Object recordWatchCache = Cache.Org.get(key);
        Map<String, Object> recordWatcherMap = RecordWatcherController.getRecordWatcher(recordWatcherList[0].Record_Id__c, recordWatcherList[0].sObjectName__c, null);
        if(recordWatcherMap!=null && !recordWatcherMap.isEmpty()){
            String recordId = String.valueOf(recordWatcherMap.get('recordId'));
            if(recordId==recordWatcherList[0].Record_Id__c){
                Map<String, Object> userActivityMap = (Map<String, Object>)(JSON.deserializeUntyped(JSON.serialize(recordWatcherMap.get('userIdActivityMap'))));
                System.debug('WorkerIds=>'+userActivityMap);
                
                String currentUserId = String.valueOf(recordWatcherList[0].User_Id__c);
                RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
                rw.objectApiName = recordWatcherList[0].sObjectName__c;
                rw.recordId = recordWatcherList[0].Record_Id__c;

                if(Boolean.valueOf(recordWatcherList[0].Is_Watching__c)){
                    userActivityMap.put(currentUserId, true); 
                    Map<Id, Boolean> userActMap = new Map<Id, Boolean>();
                    for(Id userId : userActivityMap.keySet()){
                        userActMap.put(userId, Boolean.valueOf(userActivityMap.get(userId)));
                    }

                    rw.userIdActivityMap = userActMap; 
                    Cache.Org.put(key, rw);
                }else{
                    if(userActivityMap.get(currentUserId)!=null){
                        userActivityMap.put(currentUserId, false);
                        Map<Id, Boolean> userActMap = new Map<Id, Boolean>();
                        for(Id userId : userActivityMap.keySet()){
                            userActMap.put(userId, Boolean.valueOf(userActivityMap.get(userId)));
                        }

                        rw.userIdActivityMap = userActMap; 
                        Cache.Org.put(key, rw);
                    }
                }
            }
        }else{
            Map<Id, Boolean> userActivityMap = new Map<Id, Boolean>();
            RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
            rw.objectApiName = recordWatcherList[0].sObjectName__c;
            rw.recordId = recordWatcherList[0].Record_Id__c;

            if(recordWatcherList[0].Is_Watching__c){
                userActivityMap.put(String.valueOf(recordWatcherList[0].User_Id__c), true);
                rw.userIdActivityMap = userActivityMap; 
                Cache.Org.put(key, rw);
            }
        }
    }
}