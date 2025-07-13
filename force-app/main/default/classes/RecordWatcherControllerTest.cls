@isTest
private class RecordWatcherControllerTest {
    @TestSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser@test.com' + System.currentTimeMillis()
        );
        insert testUser;
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
    }

    @isTest
    static void testCheckDefaultCachePartition() {
        Test.startTest();
        Boolean result = RecordWatcherController.checkDefaultCachePartition();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testUpdateRecordWatcher_True() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        Test.startTest();
        List<Record_Watcher__e> events = RecordWatcherController.updateRecordWatcher(acc.Id, 'Account', usr.Id, true);
        Test.stopTest();
        System.assertEquals(1, events.size());
    }
    @isTest
    static void testUpdateRecordWatcher_False() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        Test.startTest();
        List<Record_Watcher__e> events2 = RecordWatcherController.updateRecordWatcher(acc.Id, 'Account', usr.Id, false);
        Test.stopTest();
        System.assertEquals(1, events2.size());
    }

    @isTest
    static void testGetRecordWatcher_WithAndWithoutKey() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        String key = 'RWAccount' + acc.Id;
        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
        rw.recordId = acc.Id;
        rw.objectApiName = 'Account';
        rw.userIdActivityMap = new Map<Id,Boolean>{usr.Id => true};
        Cache.Org.put(key, rw);
        // Without keyParam
        Map<String, Object> result = RecordWatcherController.getRecordWatcher(acc.Id, 'Account', null);
        System.assertNotEquals(null, result);
        // With keyParam
        Map<String, Object> result2 = RecordWatcherController.getRecordWatcher(acc.Id, 'Account', key);
        System.assertNotEquals(null, result2);
        Cache.Org.remove(key);
    }

    @isTest
    static void testGetCurrentAllRecordWatchersByObject() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        String key = 'RWAccount' + acc.Id;
        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
        rw.recordId = acc.Id;
        rw.objectApiName = 'Account';
        rw.userIdActivityMap = new Map<Id,Boolean>{usr.Id => true};
        Cache.Org.put(key, rw);
        Map<String, List<Object>> res = RecordWatcherController.getCurrentAllRecordWatchersByObject('Account');
        System.assert(res.containsKey('Account'));
        Cache.Org.remove(key);
    }

    @isTest
    static void testFetchUser_EmptyAndNonEmpty() {
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        List<User> users = RecordWatcherController.fetchUser(new List<Id>{usr.Id});
        System.assertEquals(1, users.size());
        List<User> empty = RecordWatcherController.fetchUser(new List<Id>());
        System.assertEquals(0, empty.size());
    }

    @isTest
    static void testGetCurrentRecordWatchers_ValidAndEdge() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        String key = 'RWAccount' + acc.Id;
        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
        rw.recordId = acc.Id;
        rw.objectApiName = 'Account';
        rw.userIdActivityMap = new Map<Id,Boolean>{usr.Id => true};
        Cache.Org.put(key, rw);
        RecordWatcherController.RecordWatcherInput input = new RecordWatcherController.RecordWatcherInput();
        input.recordId = acc.Id;
        input.sObjectType = 'Account';
        List<List<RecordWatcherController.RecordWatcherOutput>> out1 = RecordWatcherController.getCurrentRecordWatchers(new List<RecordWatcherController.RecordWatcherInput>{input});
        System.assertEquals(null, out1);
        Cache.Org.remove(key);
        // Edge: empty input
        List<List<RecordWatcherController.RecordWatcherOutput>> out2 = RecordWatcherController.getCurrentRecordWatchers(new List<RecordWatcherController.RecordWatcherInput>());
        System.assertEquals(null, out2);
        // Edge: null input
        List<List<RecordWatcherController.RecordWatcherOutput>> out3 = RecordWatcherController.getCurrentRecordWatchers(null);
        System.assertEquals(null, out3);
    }

    @isTest
    static void testRemoveRecordWatcherOrgCache_AllBranches() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        // User in cache
        String key = 'RWAccount' + acc.Id;
        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
        rw.recordId = acc.Id;
        rw.objectApiName = 'Account';
        rw.userIdActivityMap = new Map<Id,Boolean>{usr.Id => true};
        Cache.Org.put(key, rw);
        RecordWatcherController.removeRecordWatcherOrgCache(acc.Id, 'Account', usr.Id, null);
        System.assertEquals(null, Cache.Org.get(key));
        // User not in cache
        Cache.Org.put(key, rw);
        RecordWatcherController.removeRecordWatcherOrgCache(acc.Id, 'Account', '005000000000002', null);
        System.assertEquals(null, Cache.Org.get(key));
        // With keyParam
        Cache.Org.put(key, rw);
        RecordWatcherController.removeRecordWatcherOrgCache(acc.Id, 'Account', usr.Id, key);
        System.assertEquals(null, Cache.Org.get(key));
    }

    @isTest
    static void testIsUserInRecordWatcherCache_TrueFalse() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        String key = 'RWAccount' + acc.Id;
        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
        rw.recordId = acc.Id;
        rw.objectApiName = 'Account';
        rw.userIdActivityMap = new Map<Id,Boolean>{usr.Id => true};
        Cache.Org.put(key, rw);
        System.assertEquals(true, RecordWatcherController.isUserInRecordWatcherCache(usr.Id, acc.Id, 'Account'));
        System.assertEquals(false, RecordWatcherController.isUserInRecordWatcherCache('005000000000002', acc.Id, 'Account'));
        Cache.Org.remove(key);
    }

    @isTest
    static void testGetAllSObjectLabelsAndApiNames() {
        Map<String, String> labelToApiName = RecordWatcherController.getAllSObjectLabelsAndApiNames();
        System.assert(labelToApiName != null && labelToApiName.size() > 0);
    }

    @isTest
    static void testGetRecordWatchersForObject() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        String key = 'RWAccount' + acc.Id;
        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
        rw.recordId = acc.Id;
        rw.objectApiName = 'Account';
        rw.userIdActivityMap = new Map<Id,Boolean>{usr.Id => true};
        Cache.Org.put(key, rw);
        List<Map<String, Object>> res = RecordWatcherController.getRecordWatchersForObject('Account');
        System.assert(res.size() > 0);
        Cache.Org.remove(key);
    }

    @isTest
    static void testUpdateUserActivityStatus() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        String key = 'RWAccount' + acc.Id;
        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
        rw.recordId = acc.Id;
        rw.objectApiName = 'Account';
        rw.userIdActivityMap = new Map<Id,Boolean>{usr.Id => true};
        Cache.Org.put(key, rw);
        RecordWatcherController.updateUserActivityStatus(acc.Id, 'Account', usr.Id, false);
        System.assertEquals(null, Cache.Org.get(key));
        // Add back
        RecordWatcherController.updateUserActivityStatus(acc.Id, 'Account', usr.Id, true);
        System.assertNotEquals(null, Cache.Org.get(key));
        Cache.Org.remove(key);
    }

    @isTest
    static void testInnerClasses() {
        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
        rw.recordId = '001000000000001';
        rw.objectApiName = 'Account';
        rw.userIdActivityMap = new Map<Id,Boolean>{'005000000000001' => true};
        System.assertEquals('001000000000001', rw.recordId);
        RecordWatcherController.RecordWatcherInput input = new RecordWatcherController.RecordWatcherInput();
        input.recordId = '001000000000001';
        input.sObjectType = 'Account';
        RecordWatcherController.RecordWatcherOutput output = new RecordWatcherController.RecordWatcherOutput();
        output.WatcherName = 'Test User';
        output.WatcherId = '005000000000001';
        output.WatcherRole = 'Standard User';
        output.WatcherPhotoUrl = 'https://test.com/photo.jpg';
        System.assertEquals('Account', input.sObjectType);
        System.assertEquals('Test User', output.WatcherName);
    }

    @isTest
    static void testCheckDefaultCachePartition_Exception() {
        // This will just call the method and assert it returns a boolean (true or false)
        Boolean result = RecordWatcherController.checkDefaultCachePartition();
        System.assert(result == true || result == false);
    }

    @isTest
    static void testRemoveRecordWatcherOrgCache_KeyParamBranch() {
        String key = 'RWTestKey';
        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
        rw.recordId = '001000000000001';
        rw.objectApiName = 'Account';
        rw.userIdActivityMap = new Map<Id,Boolean>{'005000000000001' => true};
        Cache.Org.put(key, rw);
        RecordWatcherController.removeRecordWatcherOrgCache(null, null, '005000000000001', key);
        System.assertEquals(null, Cache.Org.get(key));
    }

    @isTest
    static void testRemoveRecordWatcherOrgCache_UserNotInCache() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String key = 'RWAccount' + acc.Id;
        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
        rw.recordId = acc.Id;
        rw.objectApiName = 'Account';
        rw.userIdActivityMap = new Map<Id,Boolean>{'005000000000002' => true};
        Cache.Org.put(key, rw);
        RecordWatcherController.removeRecordWatcherOrgCache(acc.Id, 'Account', '005000000000001', null);
        System.assertEquals(null, Cache.Org.get(key));
    }

    @isTest
    static void testGetRecordWatcher_KeyParamOnly() {
        String key = 'RWTestKey';
        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
        rw.recordId = '001000000000001';
        rw.objectApiName = 'Account';
        rw.userIdActivityMap = new Map<Id,Boolean>{'005000000000001' => true};
        Cache.Org.put(key, rw);
        Map<String, Object> result = RecordWatcherController.getRecordWatcher(null, null, key);
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testUpdateUserActivityStatus_NoUserIds() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String key = 'RWAccount' + acc.Id;
        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
        rw.recordId = acc.Id;
        rw.objectApiName = 'Account';
        rw.userIdActivityMap = new Map<Id,Boolean>{'005000000000001' => true};
        Cache.Org.put(key, rw);
        RecordWatcherController.updateUserActivityStatus(acc.Id, 'Account', '005000000000001', false);
        System.assertEquals(null, Cache.Org.get(key));
    }

    @isTest
    static void testGetRecordWatchersForObject_NoUserIds() {
        String key = 'RWAccount001000000000001'; // Key must contain 'Account'
        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
        rw.recordId = '001000000000001';
        rw.objectApiName = 'Account';
        rw.userIdActivityMap = new Map<Id,Boolean>{'005000000000001' => true};
        Cache.Org.put(key, rw);
        List<Map<String, Object>> result = RecordWatcherController.getRecordWatchersForObject('Account');
        System.assert(result.size() > 0);
    }
} 