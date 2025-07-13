# RecordWatcher API Reference

## Table of Contents
1. [Apex Classes](#apex-classes)
2. [Platform Events](#platform-events)
3. [Components](#components)
4. [Triggers](#triggers)
5. [Custom Objects](#custom-objects)
6. [Cache Operations](#cache-operations)
7. [Error Codes](#error-codes)

## Apex Classes

### RecordWatcherController

Main controller class for record watching functionality.

#### Methods

##### `updateRecordWatcher(Id recordId, String sObjType, Id userId, Boolean isWatching)`

Publishes platform events for record watching.

**Signature**:
```apex
@AuraEnabled(cacheable=false)
public static List<Record_Watcher__e> updateRecordWatcher(
    Id recordId, 
    String sObjType, 
    Id userId, 
    Boolean isWatching
)
```

**Parameters**:
- `recordId` (Id) - Record ID to watch
- `sObjType` (String) - Object type (optional, auto-detected from recordId)
- `userId` (Id) - User ID watching the record
- `isWatching` (Boolean) - Whether user is watching (true) or stopped watching (false)

**Returns**: `List<Record_Watcher__e>` - List of published events

**Example**:
```apex
List<Record_Watcher__e> events = RecordWatcherController.updateRecordWatcher(
    '001XXXXXXXXXXXXXXX', 
    'Account', 
    '005XXXXXXXXXXXXXXX', 
    true
);
```

##### `isUserInRecordWatcherCache(Id userId, Id recordId, String objectApiName)`

Checks if user is already watching a record.

**Signature**:
```apex
@AuraEnabled
public static Boolean isUserInRecordWatcherCache(
    Id userId, 
    Id recordId, 
    String objectApiName
)
```

**Parameters**:
- `userId` (Id) - User ID to check
- `recordId` (Id) - Record ID to check
- `objectApiName` (String) - Object API name

**Returns**: `Boolean` - True if user is in cache, false otherwise

**Example**:
```apex
Boolean isWatching = RecordWatcherController.isUserInRecordWatcherCache(
    '005XXXXXXXXXXXXXXX', 
    '001XXXXXXXXXXXXXXX', 
    'Account'
);
```

##### `getRecordWatcher(Id recId, String objApiName, String keyParam)`

Retrieves record watcher information from cache.

**Signature**:
```apex
@AuraEnabled
public static Map<String, Object> getRecordWatcher(
    Id recId, 
    String objApiName, 
    String keyParam
)
```

**Parameters**:
- `recId` (Id) - Record ID
- `objApiName` (String) - Object API name
- `keyParam` (String) - Optional cache key parameter

**Returns**: `Map<String, Object>` - Cache data or null if not found

**Example**:
```apex
Map<String, Object> cacheData = RecordWatcherController.getRecordWatcher(
    '001XXXXXXXXXXXXXXX', 
    'Account', 
    null
);
```

##### `removeRecordWatcherOrgCache(Id recordId, String objectApiName, String userId, String keyParam)`

Removes user from record watcher cache.

**Signature**:
```apex
@AuraEnabled(cacheable=false)
public static void removeRecordWatcherOrgCache(
    Id recordId, 
    String objectApiName, 
    String userId, 
    String keyParam
)
```

**Parameters**:
- `recordId` (Id) - Record ID
- `objectApiName` (String) - Object API name
- `userId` (String) - User ID to remove
- `keyParam` (String) - Optional cache key parameter

**Example**:
```apex
RecordWatcherController.removeRecordWatcherOrgCache(
    '001XXXXXXXXXXXXXXX', 
    'Account', 
    '005XXXXXXXXXXXXXXX', 
    null
);
```

##### `getCurrentRecordWatchers(List<RecordWatcherInput> rwInput)`

Invocable method for getting current record watchers.

**Signature**:
```apex
@InvocableMethod(label='Get Current Record Watchers')
public static List<List<RecordWatcherOutput>> getCurrentRecordWatchers(
    List<RecordWatcherInput> rwInput
)
```

**Parameters**:
- `rwInput` (List<RecordWatcherInput>) - List of input parameters

**Returns**: `List<List<RecordWatcherOutput>>` - List of watcher information

**Example**:
```apex
RecordWatcherInput input = new RecordWatcherInput();
input.recordId = '001XXXXXXXXXXXXXXX';
input.sObjectType = 'Account';

List<RecordWatcherInput> inputs = new List<RecordWatcherInput>{input};
List<List<RecordWatcherOutput>> results = RecordWatcherController.getCurrentRecordWatchers(inputs);
```

##### `checkDefaultCachePartition()`

Checks if default cache partition is available.

**Signature**:
```apex
@AuraEnabled
public static Boolean checkDefaultCachePartition()
```

**Returns**: `Boolean` - True if default partition exists

**Example**:
```apex
Boolean hasCache = RecordWatcherController.checkDefaultCachePartition();
```

##### `fetchUser(List<Id> userId)`

Fetches User records for a list of user IDs.

**Signature**:
```apex
@AuraEnabled 
public static List<User> fetchUser(List<Id> userId)
```

**Parameters**:
- `userId` (List<Id>) - List of user IDs

**Returns**: `List<User>` - List of User records

**Example**:
```apex
List<User> users = RecordWatcherController.fetchUser(
    new List<Id>{'005XXXXXXXXXXXXXXX', '005YYYYYYYYYYYYYYY'}
);
```

##### `getAllSObjectLabelsAndApiNames()`

Returns a map of all sObject labels to their API names.

**Signature**:
```apex
@AuraEnabled
public static Map<String, String> getAllSObjectLabelsAndApiNames()
```

**Returns**: `Map<String, String>` - Map with label as key and API name as value

**Example**:
```apex
Map<String, String> objectMap = RecordWatcherController.getAllSObjectLabelsAndApiNames();
```

##### `getRecordWatchersForObject(String objectApiName)`

Gets record watchers for an object with user activity status.

**Signature**:
```apex
@AuraEnabled
public static List<Map<String, Object>> getRecordWatchersForObject(String objectApiName)
```

**Parameters**:
- `objectApiName` (String) - Object API name

**Returns**: `List<Map<String, Object>>` - List of record watcher details

**Example**:
```apex
List<Map<String, Object>> watchers = RecordWatcherController.getRecordWatchersForObject('Account');
```

##### `updateUserActivityStatus(Id recordId, String objectApiName, Id userId, Boolean isActive)`

Updates user activity status for a record watcher.

**Signature**:
```apex
@AuraEnabled
public static void updateUserActivityStatus(
    Id recordId, 
    String objectApiName, 
    Id userId, 
    Boolean isActive
)
```

**Parameters**:
- `recordId` (Id) - Record ID
- `objectApiName` (String) - Object API name
- `userId` (Id) - User ID
- `isActive` (Boolean) - Whether user is active

**Example**:
```apex
RecordWatcherController.updateUserActivityStatus(
    '001XXXXXXXXXXXXXXX', 
    'Account', 
    '005XXXXXXXXXXXXXXX', 
    true
);
```

#### Inner Classes

##### RecordWatcher
Data structure for cache storage.

```apex
public class RecordWatcher {
    public String recordId;
    public String objectApiName;
    public Map<Id,Boolean> userIdActivityMap;
}
```

##### RecordWatcherInput
Input structure for invocable methods.

```apex
public class RecordWatcherInput {
    @InvocableVariable(label='Record ID')
    public String recordId;
    
    @InvocableVariable(label='sObject Type')
    public String sObjectType;
}
```

##### RecordWatcherOutput
Output structure for invocable methods.

```apex
public class RecordWatcherOutput {
    @InvocableVariable(label='Name')
    public String WatcherName;
    
    @InvocableVariable(label='Id')
    public String WatcherId;
    
    @InvocableVariable(label='Role')
    public String WatcherRole;
    
    @InvocableVariable(label='Photo URL')
    public String WatcherPhotoUrl;
}
```

### ObjectsDynamicPicklistDesignAttr

Utility class for dynamic picklist generation.

#### Methods

##### `getValues()`

Returns list of sObject labels and API names for picklist.

**Signature**:
```apex
public static List<Map<String, String>> getValues()
```

**Returns**: `List<Map<String, String>>` - List of label/API name pairs

## Platform Events

### Record_Watcher__e

Primary platform event for record watching synchronization.

#### Event Properties
- **Event Type**: High Volume
- **Publish Behavior**: Publish Immediately
- **Channel**: `/event/Record_Watcher__e`

#### Fields

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| `Record_Id__c` | Text(20) | Yes | Record ID being watched |
| `sObjectName__c` | Text | Yes | Object API name |
| `User_Id__c` | Text | Yes | User ID watching the record |
| `Is_Watching__c` | Boolean | Yes | Whether user is watching (true) or stopped watching (false) |

#### Event Publishing

**Apex**:
```apex
Record_Watcher__e event = new Record_Watcher__e();
event.Record_Id__c = '001XXXXXXXXXXXXXXX';
event.sObjectName__c = 'Account';
event.User_Id__c = '005XXXXXXXXXXXXXXX';
event.Is_Watching__c = true;

EventBus.publish(event);
```

**JavaScript (EMP API)**:
```javascript
// Subscribe to events
subscribe('/event/Record_Watcher__e', -1, messageCallback)
    .then(response => {
        console.log('Subscribed to channel:', response.channel);
    });
```

## Components

### Aura Components

#### RecordWatcher.cmp

Main Aura component for record watching.

**Implements**: `force:hasRecordId`, `force:hasSObjectName`, `flexipage:availableForAllPageTypes`, `flexipage:availableForRecordHome`

**Attributes**:
- `currentUserId` (String) - Current user ID
- `workers` (List) - List of current watchers
- `isWorking` (Boolean) - Whether component is active
- `updateRecId` (String) - Current record ID
- `currentTabId` (String) - Current tab ID

**Methods**:
- `doInit()` - Component initialization
- `getAllTabInfo()` - Analyzes open tabs
- `updateRecordRelatedToTab()` - Updates record watching status
- `onTabFocused()` - Handles tab focus events
- `onTabClosed()` - Handles tab close events

#### showToast.cmp

Utility component for displaying toast notifications.

**Methods**:
- `showToast(type, message)` - Displays toast notification

### Lightning Web Components

#### recordWatcherLWC

Modern LWC version of record watcher functionality.

**Targets**: `lightning__RecordPage`

**Properties**:
- `@api recordId` - Current record ID
- `@api sObjectName` - Object API name

**Tracked Properties**:
- `workers` - List of current watchers
- `isWorking` - Whether component is active
- `currentUserId` - Current user ID
- `updateRecId` - Current record ID

**Methods**:
- `connectedCallback()` - Component initialization
- `disconnectedCallback()` - Component cleanup
- `subscribe()` - Subscribe to platform events
- `unsubscribe()` - Unsubscribe from platform events
- `getAllTabInfo()` - Get tab information
- `updateRecordRelatedToTab()` - Update record watching
- `refresh()` - Refresh component data
- `handleTabClosed()` - Handle tab close

#### recordWatchersModal

Modal component for displaying current record watchers.

**Properties**:
- `recordWatchers` - List of watchers to display
- `showModal` - Whether modal is visible

**Methods**:
- `handleClose()` - Close modal
- `handleOpenUser()` - Open user record

#### recordWatcherObjectsList

Component for listing available objects.

**Properties**:
- `objects` - List of available objects

#### recordWatchersAgentForce

Agent-specific component for Service Console.

**Targets**: `lightning__AppPage`, `lightning__Home`

#### recordWatcherTab

Tab component for displaying watcher information.

**Targets**: `lightning__Tab`

## Triggers

### RecordWatcherEventTrigger

Processes platform events after insert.

**Object**: `Record_Watcher__e`  
**Timing**: After Insert

**Functionality**:
- Updates org cache with user activity
- Manages user activity maps
- Handles multiple users watching same record

**Trigger Logic**:
```apex
trigger RecordWatcherEventTrigger on Record_Watcher__e (after insert) {
    List<Record_Watcher__e> recordWatcherList = Trigger.New;
    
    if (!recordWatcherList.isEmpty()) {
        String formattedObjApiName = recordWatcherList[0].sObjectName__c.replace('_','');
        String key = 'RW' + formattedObjApiName + recordWatcherList[0].Record_Id__c;
        
        // Process each event
        for (Record_Watcher__e event : recordWatcherList) {
            // Update cache logic
        }
    }
}
```

### RecordWatcherLogoutEventTrg

Handles user logout events.

**Object**: `LogoutEventStream`  
**Timing**: After Insert

**Functionality**:
- Removes logged-out users from cache
- Sends email notifications
- Cleans up user activity

## Custom Objects

### Record_Watcher__e

Platform event object for record watching.

#### Fields

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| `Record_Id__c` | Text(20) | Yes | Record ID being watched |
| `sObjectName__c` | Text | Yes | Object API name |
| `User_Id__c` | Text | Yes | User ID watching the record |
| `Is_Watching__c` | Boolean | Yes | Whether user is watching |

#### Object Properties
- **Event Type**: High Volume
- **Publish Behavior**: Publish Immediately
- **Label**: Record Watcher
- **Plural Label**: Record Watchers

## Cache Operations

### Cache Key Format

Cache keys follow the pattern: `RW{ObjectName}{RecordId}`

**Examples**:
- `RWAccount001XXXXXXXXXXXXXXX`
- `RWContact003XXXXXXXXXXXXXXX`
- `RWCase500XXXXXXXXXXXXXXX`

### Cache Data Structure

```apex
{
    "recordId": "001XXXXXXXXXXXXXXX",
    "objectApiName": "Account",
    "userIds": ["005XXXXXXXXXXXXXXX", "005YYYYYYYYYYYYYYY"],
    "userIdActivityMap": {
        "005XXXXXXXXXXXXXXX": true,
        "005YYYYYYYYYYYYYYY": true
    }
}
```

### Cache Operations

#### Reading from Cache
```apex
String key = 'RWAccount001XXXXXXXXXXXXXXX';
Object cacheData = Cache.Org.get(key);
```

#### Writing to Cache
```apex
RecordWatcherController.RecordWatcher rw = new RecordWatcherController.RecordWatcher();
rw.recordId = '001XXXXXXXXXXXXXXX';
rw.objectApiName = 'Account';
rw.userIdActivityMap = userActivityMap;
Cache.Org.put(key, rw);
```

#### Removing from Cache
```apex
Cache.Org.remove(key);
```

#### Getting All Cache Keys
```apex
Set<String> cacheKeys = Cache.Org.getKeys();
```

## Error Codes

### Common Error Messages

| Error Code | Description | Solution |
|------------|-------------|----------|
| `CACHE_PARTITION_NOT_FOUND` | Default cache partition not configured | Configure default cache partition in Setup → Platform Cache |
| `EVENT_PUBLISH_FAILED` | Platform event publishing failed | Check user permissions and event configuration |
| `COMPONENT_INIT_FAILED` | Component initialization failed | Check component permissions and object access |
| `SUBSCRIPTION_FAILED` | Event subscription failed | Check EMP API configuration and network connectivity |
| `CACHE_ACCESS_DENIED` | Cache access denied | Check cache permissions and partition configuration |

### Debug Information

#### Platform Event Monitoring
```apex
// Monitor events in debug logs
System.debug('Published Event: ' + rwList);
System.debug('Event payload: ' + JSON.serialize(rwList));
```

#### Cache Monitoring
```apex
// Check cache contents
Object cacheData = Cache.Org.get('RWAccount001XXXXXXXXXXXXXXX');
System.debug('Cache Data: ' + cacheData);
```

#### Component Debug
```javascript
// Enable component debugging
console.log('Component State:', this.workers);
console.log('Current Record:', this.updateRecId);
console.log('Platform event received:', response);
```

### Performance Monitoring

#### Cache Performance
```apex
// Monitor cache usage
Set<String> cacheKeys = Cache.Org.getKeys();
System.debug('Cache keys count: ' + cacheKeys.size());
```

#### Event Volume
```apex
// Monitor event publishing frequency
System.debug('Events published in this transaction: ' + Limits.getPublishImmediateDML());
```

#### Component Performance
```javascript
// Monitor component render performance
console.time('componentUpdate');
// Component update logic
console.timeEnd('componentUpdate');
```

---

**Version**: 1.0  
**Last Updated**: 2025 
**Compatibility**: Salesforce API 62.0+ 