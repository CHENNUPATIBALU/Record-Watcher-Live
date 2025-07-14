@isTest
private class RecordWatcherLogoutEventTrgTest {
    @TestSetup
    static void setupTestData() {
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser+' + System.currentTimeMillis() + '@test.com'
        );
        insert testUser;

        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Simulate the user watching the record
        String key = 'RWAccount' + testAccount.Id;
        RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
        rw.recordId = testAccount.Id;
        rw.objectApiName = 'Account';
        rw.userIdActivityMap = new Map<Id, Boolean>{ testUser.Id => true };
        Cache.Org.put(key, rw);
    }

    @isTest
    static void testLogoutEventRemovesUserFromCache() {
        // Get test user and account
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        // Ensure cache is present before logout
        String key = 'RWAccount' + testAccount.Id;
        Object cached = Cache.Org.get(key);
        System.assertNotEquals(null, cached, 'Cache should exist before logout');

        // Simulate logout event
        Test.startTest();
        LogoutEventStream logoutEvt = new LogoutEventStream(UserId = testUser.Id);
        EventBus.publish(logoutEvt);
        Test.stopTest();

        // Cache should be removed after logout
        Object afterLogout = Cache.Org.get(key);
        System.assertEquals(null, afterLogout, 'Cache should be removed after logout');
    }

    @isTest
    static void testLogoutEventWithNoMatchingCache() {
        // Insert a logout event for a user not in cache
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        // Remove all cache entries
        for (String key : Cache.Org.getKeys()) {
            Cache.Org.remove(key);
        }
        Test.startTest();
        LogoutEventStream logoutEvt = new LogoutEventStream(UserId = testUser.Id);
        EventBus.publish(logoutEvt);
        Test.stopTest();
        // No error should occur, nothing to assert
        System.assert(true, 'Trigger should handle no matching cache gracefully');
    }
}