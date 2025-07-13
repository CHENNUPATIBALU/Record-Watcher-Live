trigger RecordWatcherLogoutEventTrg on LogoutEventStream (after insert) {
    
    List<LogoutEventStream> logoutEventStreams = Trigger.New;
    
    List<Id> loggedOutUserIds = new List<Id>();
    
    for(LogoutEventStream les: logoutEventStreams){
        loggedOutUserIds.add(les.UserId);
    }
    
    if(!loggedOutUserIds.isEmpty()){
        Set<String> cacheKeys = Cache.Org.getKeys();
        List<String> cacheKeysToRemove = new List<String>();
        for(String key: cacheKeys){
            Object cacheObj = Cache.Org.get(key);
            Map<String, Object> recordWatcherObj = (Map<String, Object>)(JSON.deserializeUntyped(JSON.serialize(cacheObj)));
            Map<String, Object> userActivityMap = (Map<String, Object>)(JSON.deserializeUntyped(JSON.serialize(recordWatcherObj.get('userIdActivityMap'))));
            System.debug('WorkerIds=>'+userActivityMap.keySet());
            if(userActivityMap!=null && !userActivityMap.isEmpty()){
                if(userActivityMap.containsKey(loggedOutUserIds[0])){
                    RecordWatcherController.removeRecordWatcherOrgCache(null,null,loggedOutUserIds[0], key);
                }
            }
        }
    }
}
