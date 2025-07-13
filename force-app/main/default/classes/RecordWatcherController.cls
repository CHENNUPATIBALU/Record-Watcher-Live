public with sharing class RecordWatcherController {
    
    public class RecordWatcher{
        public String recordId;
        public String objectApiName;
        public Map<Id,Boolean> userIdActivityMap;
    }
    
    /**
     * Checks if the default cache partition is available in the org.
     * @return true if the default cache partition exists, false otherwise.
     */
    @AuraEnabled
    public static Boolean checkDefaultCachePartition(){
        String defaultPartition = null;
        try{
            defaultPartition = Cache.Org.getName();
            if(defaultPartition!=null){
                return true;
            }else{
                return false;
            }
        }catch(Exception e){
            System.debug(e.getLineNumber()+': '+e.getMessage());
        }
        
        return false;
    }
    
    /**
     * Publishes a RecordWatcher event and returns the list of events published.
     * @param recordId The record Id to watch.
     * @param sObjType The sObject type of the record.
     * @param userId The user Id who is watching.
     * @return List of Record_Watcher__e events published.
     */
    @AuraEnabled(cacheable=false)
    public static List<Record_Watcher__e> updateRecordWatcher(Id recordId, String sObjType, Id userId, Boolean isWatching){
        
        List<Record_Watcher__e> rwList = new List<Record_Watcher__e>();
        Record_Watcher__e rw = new Record_Watcher__e();
        rw.Record_Id__c = recordId;
        String formattedsObjType = recordId.getSObjectType().getDescribe().getName().replace('_','');
        rw.sObjectName__c = formattedsObjType;
        rw.User_Id__c = userId;
        rw.Is_Watching__c = isWatching;
        
        rwList.add(rw);
        
        EventBus.publish(rwList);
        
        return rwList;
    }
    
    /**
     * Removes a user from the record watcher org cache for a given record and object.
     * @param recordId The record Id.
     * @param objectApiName The object API name.
     * @param userId The user Id to remove.
     * @param keyParam Optional cache key parameter.
     */
    @AuraEnabled(cacheable=false)
    public static void removeRecordWatcherOrgCache(Id recordId, String objectApiName, String userId, String keyParam){
        String key = null;
        Map<String, Object> recordWatcherMap = new Map<String, Object>();
        if(keyParam!=null && userId!=null && recordId==null && recordId.getSObjectType().getDescribe().getName()==null){
            key = keyParam;
            recordWatcherMap = getRecordWatcher(recordId, recordId.getSObjectType().getDescribe().getName(), key);
        }else{
            String formattedObjApiName = recordId.getSObjectType().getDescribe().getName().replace('_','');
            key = 'RW'+formattedObjApiName+recordId;
            recordWatcherMap = getRecordWatcher(recordId, recordId.getSObjectType().getDescribe().getName(), null);
        }
        
        if(key!=null){
            if(recordWatcherMap!=null && !recordWatcherMap.isEmpty()){
                Map<String, Object> userActivityMap = (Map<String, Object>)(JSON.deserializeUntyped(JSON.serialize(recordWatcherMap.get('userIdActivityMap'))));
                System.debug('WorkerIds=>'+userActivityMap);
                if(!userActivityMap.isEmpty() && userActivityMap.size()>0 && userActivityMap.containsKey(userId)){
                    userActivityMap.remove(userId);
                    
                    if(!userActivityMap.isEmpty()){
                        Map<Id, Boolean> userActMap = new Map<Id, Boolean>();
                        for(Id usId : userActivityMap.keySet()){
                            userActMap.put(usId, Boolean.valueOf(userActivityMap.get(usId)));
                        }

                        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
                        rw.objectApiName = recordId.getSObjectType().getDescribe().getName();
                        rw.recordId = recordId;
                        rw.userIdActivityMap = userActMap;
                        Cache.Org.put(key, rw);
                    }else{
                        Cache.Org.remove(key);
                    }
                    
                    List<Record_Watcher__e> rwList = new List<Record_Watcher__e>();
                    Record_Watcher__e rwe = new Record_Watcher__e();
                    rwe.Record_Id__c = recordId;
                    rwe.sObjectName__c = recordId.getSObjectType().getDescribe().getName().replace('_','');
                    rwe.User_Id__c = userId;
                    rwe.Is_Watching__c = false;
                    
                    rwList.add(rwe);
                    
                    EventBus.publish(rwList);
                }else{
                    Cache.Org.remove(key);
                }
            }   
        }
    }
    
    /**
     * Gets the record watcher cache for a given record and object.
     * @param recId The record Id.
     * @param objApiName The object API name.
     * @param keyParam Optional cache key parameter.
     * @return Map of record watcher data, or null if not found.
     */
    @AuraEnabled
    public static Map<String, Object> getRecordWatcher(Id recId, String objApiName, String keyParam){
        String key = null;
        if(keyParam!=null){
            key = keyParam;
        }else{
            String formattedObjApiName = recId.getSObjectType().getDescribe().getName().replace('_','');
            key = 'RW'+formattedObjApiName+recId;
        }
        
        if(key!=null){
         	Object recordWatchCache = Cache.Org.get(key);
        
            if(recordWatchCache!=null){
                Map<String, Object> recordWatcherMap = (Map<String, Object>)(JSON.deserializeUntyped(JSON.serialize(recordWatchCache)));
                System.debug('Workers='+recordWatcherMap);
                return recordWatcherMap;
            }   
        }
        
        return null;
    }
    
    /**
     * Gets all record watcher caches for a given object API name.
     * @param objectApiName The object API name.
     * @return Map of object API name to list of record watcher cache objects.
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, List<Object>> getCurrentAllRecordWatchersByObject(String objectApiName){
        String formattedObjApiName = objectApiName.replace('_','');
        Map<String, List<Object>> objectRecordWatchersMap = new Map<String, List<Object>>();
        
        Set<String> cacheKeys = Cache.Org.getKeys();
        for(String key: cacheKeys){
            if(key.contains(formattedObjApiName)){
                Object cacheObj = Cache.Org.get(key);
                if(objectRecordWatchersMap!=null && !objectRecordWatchersMap.isEmpty() && objectRecordWatchersMap.get(formattedObjApiName)!=null){
                    List<Object> mapObjList = objectRecordWatchersMap.get(formattedObjApiName);
                    if(!mapObjList.isEmpty() && !mapObjList.contains(cacheObj)){
                        mapObjList.add(cacheObj);
                        objectRecordWatchersMap.put(formattedObjApiName,mapObjList);
                    }
                }else{
                    objectRecordWatchersMap.put(formattedObjApiName,new List<Object>{cacheObj});
                }
            }
        }

        System.debug('Record Watchers Map='+objectRecordWatchersMap);
        
        return objectRecordWatchersMap;
    }
    
    /**
     * Fetches User records for a list of user Ids.
     * @param userId List of user Ids.
     * @return List of User records.
     */
    @AuraEnabled 
    public static List<user> fetchUser(List<Id> userId){
        List<User> u = [select id, Name, SmallPhotoUrl, FullPhotoUrl, Alias, UserRoleId, UserRole.Name from User where id in :userId order by Name ASC];
        return u;
    }
    
    /**
     * Gets the current record watchers for a list of input records.
     * @param rwInput List of RecordWatcherInput objects.
     * @return List of lists of RecordWatcherOutput objects.
     */
    @InvocableMethod(label='Get Current Record Watchers')
    public static List<List<RecordWatcherOutput>> getCurrentRecordWatchers(List<RecordWatcherInput> rwInput){
        List<RecordWatcherOutput> rwoList = new List<RecordWatcherOutput>();
        List<List<RecordWatcherOutput>> rwoLst = new List<List<RecordWatcherOutput>>();
        String recordId = rwInput[0].recordId;
        String objectType = rwInput[0].sObjectType;
        
        Map<String, Object> recordWatchersMap = getRecordWatcher(recordId, objectType, null);
        List<User> recordWatchers = new List<User>();
        
        if(recordWatchersMap!=null && !recordWatchersMap.isEmpty()){
            List<Object> userIds = (List<Object>)JSON.deserializeUntyped(JSON.serialize(recordWatchersMap.get('userIds')));
            List<Id> userIdsList = new List<id>();
            for(Object obj: userIds){
                userIdsList.add(String.valueOf(obj));
            }
            recordWatchers = fetchUser(userIdsList);
            
            for(User u: recordWatchers){
                RecordWatcherOutput rwo = new RecordWatcherOutput();
                rwo.WatcherName = u.Name;
                rwo.WatcherId = u.Id;
                rwo.WatcherRole = u.UserRole.Name;
                rwo.WatcherPhotoUrl = u.SmallPhotoUrl;
                rwoList.add(rwo);
            }
            rwoLst.add(rwoList);
            
            return rwoLst;
        }
        
        return null;
    }
    
    /**
     * Checks if a user is present in the record watcher cache for a given record and object API name.
     * @param userId The Id of the user to check.
     * @param recordId The Id of the record to check.
     * @param objectApiName The API name of the object.
     * @return true if the user is present in the cache, false otherwise.
     */
    @AuraEnabled
    public static Boolean isUserInRecordWatcherCache(Id userId, Id recordId, String objectApiName) {
        Map<String, Object> recordWatcherMap = getRecordWatcher(recordId, objectApiName, null);
        if (recordWatcherMap != null && recordWatcherMap.containsKey('userIdActivityMap')) {
            Map<String, Object> userActivityMap = (Map<String, Object>)(JSON.deserializeUntyped(JSON.serialize(recordWatcherMap.get('userIdActivityMap'))));
            if(userActivityMap.containsKey(userId)){
                return true;
            }
        }
        return false;
    }
    
    /**
     * Returns a map of all sObject labels to their API names.
     * @return Map with label as key and API name as value.
     */
    @AuraEnabled
    public static Map<String, String> getAllSObjectLabelsAndApiNames() {
        Map<String, String> labelToApiName = new Map<String, String>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for (String apiName : gd.keySet()) {
            Schema.SObjectType sObjType = gd.get(apiName);
            Schema.DescribeSObjectResult describe = sObjType.getDescribe();
            labelToApiName.put(describe.getLabel(), apiName.capitalize());
        }
        return labelToApiName;
    }
    
    /**
     * Gets record watchers for an object with user activity status.
     * @param objectApiName The object API name.
     * @return List of maps containing record watcher details with user activity status.
     */
    @AuraEnabled
    public static List<Map<String, Object>> getRecordWatchersForObject(String objectApiName) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        String formattedObjApiName = objectApiName.replace('_','');
        Set<String> cacheKeys = Cache.Org.getKeys();
        
        for(String key: cacheKeys){
            if(key.contains(formattedObjApiName)){
                Object cacheObj = Cache.Org.get(key);
                if(cacheObj != null) {
                    Map<String, Object> cacheMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(cacheObj));
                    
                    // Create user activity map from the stored list
                    List<Object> userIdsObj = (List<Object>)cacheMap.get('userIds');
                    Map<String, Boolean> userActivityMap = new Map<String, Boolean>();
                    
                    if(userIdsObj != null) {
                        for(Object obj: userIdsObj){
                            String userId = String.valueOf(obj);
                            userActivityMap.put(userId, true); // All stored users are considered active
                        }
                    }
                    
                    Map<String, Object> row = new Map<String, Object>();
                    row.put('recordId', cacheMap.get('recordId'));
                    row.put('objectApiName', cacheMap.get('objectApiName'));
                    row.put('userActivityMap', userActivityMap);
                    result.add(row);
                }
            }
        }
        return result;
    }

    /**
     * Updates user activity status for a record watcher.
     * @param recordId The record ID.
     * @param objectApiName The object API name.
     * @param userId The user ID.
     * @param isActive Whether the user is active on the record.
     */
    @AuraEnabled
    public static void updateUserActivityStatus(Id recordId, String objectApiName, Id userId, Boolean isActive) {
        String formattedObjApiName = objectApiName.replace('_','');
        String key = 'RW'+formattedObjApiName+recordId;
        
        Map<String, Object> recordWatcherMap = getRecordWatcher(recordId, objectApiName, null);
        Map<Id, Boolean> userActivityMap = new Map<Id, Boolean>();
        
        if(recordWatcherMap != null && recordWatcherMap.containsKey('userIds')) {
            List<Object> userIdsObj = (List<Object>)JSON.deserializeUntyped(JSON.serialize(recordWatcherMap.get('userIds')));
            
            // Convert existing list to map
            for(Object obj: userIdsObj){
                String existingUserId = String.valueOf(obj);
                userActivityMap.put(existingUserId, true);
            }
        }
        
        // Update the specific user's activity status
        String userIdStr = String.valueOf(userId);
        if(isActive) {
            userActivityMap.put(userIdStr, true);
        } else {
            userActivityMap.remove(userIdStr);
        }
        
        // Save back to cache
        if(!userActivityMap.isEmpty()) {
            RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
            rw.objectApiName = objectApiName;
            rw.recordId = recordId;
            rw.userIdActivityMap = userActivityMap;
            Cache.Org.put(key, rw);
        } else {
            Cache.Org.remove(key);
        }
    }
    
    public class RecordWatcherInput{
        @InvocableVariable(label='Record ID')
        public String recordId;
        
        @InvocableVariable(label='sObject Type')
        public String sObjectType;
    }
    
    public class RecordWatcherOutput{
        
        @InvocableVariable(label='Name')
        public String WatcherName;

        @InvocableVariable(label='Id')
        public String WatcherId;

        @InvocableVariable(label='Role')
        public String WatcherRole;

        @InvocableVariable(label='Photo URL')
        public String WatcherPhotoUrl;
    }
}