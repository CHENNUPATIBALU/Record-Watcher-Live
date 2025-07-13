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
        
        OrgWideEmailAddress[] oweaList = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = 'sdo@salesforce.com' LIMIT 1];
        
        if (!oweaList.isEmpty()) {
         	// Create a new email object
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            // Set the recipient's email address
            String[] toAddresses = new String[] {'bchennupati@salesforce.com'};
                mail.setToAddresses(toAddresses);
            
            // Set the email contents
            mail.setSubject('Record Watcher Logout Event');
            mail.setPlainTextBody(keys);
            
            mail.setOrgWideEmailAddressId(oweaList[0].Id);
            
            // Send the email
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.Email[] {mail});
            
            // Check the result
            if (results[0].isSuccess()) {
                System.debug('Email sent successfully.');
            } else {
                System.debug('Failed to send email: ' + results[0].getErrors()[0].getMessage());
            }   
        }
    }
}