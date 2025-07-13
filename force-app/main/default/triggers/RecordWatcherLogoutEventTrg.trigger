trigger RecordWatcherLogoutEventTrg on LogoutEventStream (after insert) {
    
    List<LogoutEventStream> logoutEventStreams = Trigger.New;
    
    List<Id> loggedOutUserIds = new List<Id>();
    
    for(LogoutEventStream les: logoutEventStreams){
        loggedOutUserIds.add(les.UserId);
    }
    
    String keys = '';
    
    if(!loggedOutUserIds.isEmpty()){
        Set<String> cacheKeys = Cache.Org.getKeys();
        List<String> cacheKeysToRemove = new List<String>();
        for(String key: cacheKeys){
            Object cacheObj = Cache.Org.get(key);
            List<Id> userIds = (List<Id>)(JSON.deserialize(JSON.serialize(cacheObj),RecordWatcherController.RecordWatcher.class));
            if(userIds!=null && !userIds.isEmpty()){
                if(userIds.contains(loggedOutUserIds[0])){
                    keys+=key+', ';
                    RecordWatcherController.removeRecordWatcherOrgCache(null,null,loggedOutUserIds[0], key);
                }
            }
        }
    }
}
