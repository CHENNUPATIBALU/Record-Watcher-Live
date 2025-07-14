# RecordWatcher - Salesforce Platform Event Application

<p align="left"> <img src="https://komarev.com/ghpvc/?username=RecordWatcher&label=Repository%20views&color=0e75b6&style=flat" alt="RecordWatcher" /> </p>

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Platform Events](#platform-events)
4. [Components](#components)
5. [Apex Classes](#apex-classes)
6. [Triggers](#triggers)
7. [Configuration](#configuration)
8. [Installation & Deployment](#installation--deployment)
9. [Usage Guide](#usage-guide)
10. [API Reference](#api-reference)
11. [Troubleshooting](#troubleshooting)

## Overview

RecordWatcher is a Salesforce application that enables real-time tracking of users who are currently viewing specific records. The application uses platform events to maintain synchronized state across multiple users and provides a visual indicator showing who else is currently viewing the same record.

### Key Features
- Real-time user activity tracking
- Platform event-based synchronization
- Cache-based performance optimization
- Multi-object support
- Tab-based user interface
- Automatic cleanup on tab close

## Architecture

### High-Level Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Lightning     │    │   Platform      │    │   Cache         │
│   Components    │◄──►│   Events        │◄──►│   (Org Cache)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Apex          │    │   Triggers      │    │   User          │
│   Controllers   │    │                 │    │   Interface     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Data Flow
1. User opens a record in Salesforce
2. Component checks if user is already watching the record
3. If not watching, publishes platform event
4. Trigger processes event and updates cache
5. All components subscribe to events and update UI
6. When user closes tab, cleanup event is published

## Platform Events

### Record_Watcher__e
The primary platform event used for synchronization.

**Event Type**: High Volume  
**Publish Behavior**: Publish Immediately

#### Fields
| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| `Record_Id__c` | Text(20) | Yes | Record ID being watched |
| `sObjectName__c` | Text | Yes | Object API name |
| `User_Id__c` | Text | Yes | User ID watching the record |
| `Is_Watching__c` | Boolean | Yes | Whether user is watching (true) or stopped watching (false) |

#### Event Publishing Locations
1. **RecordWatcherController.updateRecordWatcher()** - When user starts/stops watching
2. **RecordWatcherController.removeRecordWatcherOrgCache()** - When user is removed from cache

## Components

### Aura Components

#### RecordWatcher.cmp
Main component that handles record watching functionality.

**Implements**: `force:hasRecordId`, `force:hasSObjectName`, `flexipage:availableForAllPageTypes`, `flexipage:availableForRecordHome`

**Key Features**:
- Tab focus detection
- Cache-based event optimization
- Platform event subscription
- User activity tracking

**Methods**:
- `doInit()` - Component initialization
- `getAllTabInfo()` - Analyzes open tabs
- `updateRecordRelatedToTab()` - Updates record watching status
- `onTabFocused()` - Handles tab focus events
- `onTabClosed()` - Handles tab close events

### Lightning Web Components

#### recordWatchersModal
Modal component for displaying current record watchers.

## Apex Classes

### RecordWatcherController
Main controller class handling all record watching logic.

#### Key Methods

##### `updateRecordWatcher(Id recordId, String sObjType, Id userId, Boolean isWatching)`
Publishes platform events for record watching.

**Parameters**:
- `recordId` - Record ID to watch
- `sObjType` - Object type
- `userId` - User ID
- `isWatching` - Whether user is watching

**Returns**: List<Record_Watcher__e> - Published events

##### `isUserInRecordWatcherCache(Id userId, Id recordId, String objectApiName)`
Checks if user is already watching a record.

**Returns**: Boolean - True if user is in cache

##### `getRecordWatcher(Id recId, String objApiName, String keyParam)`
Retrieves record watcher information from cache.

**Returns**: Map<String, Object> - Cache data

##### `removeRecordWatcherOrgCache(Id recordId, String objectApiName, String userId, String keyParam)`
Removes user from record watcher cache.

##### `getCurrentRecordWatchers(List<RecordWatcherInput> rwInput)`
Invocable method for getting current record watchers.

**Returns**: List<List<RecordWatcherOutput>> - Watcher information

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

## Triggers

### RecordWatcherEventTrigger
Processes platform events after insert.

**Object**: Record_Watcher__e  
**Timing**: After Insert

**Functionality**:
- Updates org cache with user activity
- Manages user activity maps
- Handles multiple users watching same record

### RecordWatcherLogoutEventTrg
Handles user logout events.

**Object**: LogoutEventStream  
**Timing**: After Insert

**Functionality**:
- Removes logged-out users from cache
- Cleans up user activity

## Configuration

### Cache Configuration
The application requires a default cache partition to be configured in your Salesforce org.

**Setup Steps**:
1. Navigate to Setup → Platform Cache
2. Create a new partition or designate existing partition as default
3. Ensure sufficient memory allocation

### Permission Sets
No specific permission sets are required, but users need:
- Read access to User object
- Access to platform events
- Cache access permissions

## Installation & Deployment

### Prerequisites
- Salesforce org with Platform Cache enabled
- API version 62.0 or higher
- Lightning Experience enabled

### Deployment Steps

1. **Deploy Metadata**
   ```bash
   sfdx force:source:deploy -p force-app/main/default
   ```

2. **Configure Cache Partition**
   - Set up default cache partition in org
   - Allocate sufficient memory

3. **Add Components to Record Pages**
   - Navigate to Setup → Object Manager
   - Select target object
   - Edit Lightning Record Pages
   - Add RecordWatcher component

### Package.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>RecordWatcherController</members>
        <members>ObjectsDynamicPicklistDesignAttr</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>RecordWatcherEventTrigger</members>
        <members>RecordWatcherLogoutEventTrg</members>
        <name>ApexTrigger</name>
    </types>
    <types>
        <members>Record_Watcher__e</members>
        <name>CustomObject</name>
    </types>
    <version>62.0</version>
</Package>
```

## Usage Guide

### Adding to Record Pages

1. **Navigate to Setup**
2. **Object Manager** → Select Object
3. **Lightning Record Pages** → Edit Page
4. **Add Component** → Search "RecordWatcher"
5. **Configure Properties**:
   - Object: Select target object
6. **Save and Activate**

### User Experience

1. **Opening a Record**
   - User opens any record
   - Component automatically detects focus
   - Platform event published (if not already watching)
   - Other users see watcher indicator

2. **Multiple Users**
   - Each user sees avatars of other watchers
   - Real-time updates via platform events
   - Automatic cleanup when users close tabs

3. **Tab Management**
   - Component tracks tab focus/unfocus
   - Updates watching status accordingly
   - Handles subtab navigation

## API Reference

### Apex Methods

#### RecordWatcherController

| Method | Description | Parameters | Returns |
|--------|-------------|------------|---------|
| `updateRecordWatcher` | Publishes watching events | recordId, sObjType, userId, isWatching | List<Record_Watcher__e> |
| `isUserInRecordWatcherCache` | Checks cache status | userId, recordId, objectApiName | Boolean |
| `getRecordWatcher` | Gets cache data | recId, objApiName, keyParam | Map<String, Object> |
| `removeRecordWatcherOrgCache` | Removes from cache | recordId, objectApiName, userId, keyParam | void |
| `getCurrentRecordWatchers` | Gets watchers (Invocable) | rwInput | List<List<RecordWatcherOutput>> |

### Platform Events

#### Record_Watcher__e
```json
{
  "Record_Id__c": "001XXXXXXXXXXXXXXX",
  "sObjectName__c": "Account",
  "User_Id__c": "005XXXXXXXXXXXXXXX",
  "Is_Watching__c": true
}
```

### Cache Keys
Cache keys follow the pattern: `RW{ObjectName}{RecordId}`

**Examples**:
- `RWAccount001XXXXXXXXXXXXXXX`
- `RWContact003XXXXXXXXXXXXXXX`
```
```
## Troubleshooting

### Common Issues

#### 1. Cache Partition Not Found
**Error**: "A default partition was not found"
**Solution**: Configure default cache partition in Setup → Platform Cache

#### 2. Platform Events Not Publishing
**Error**: EventBus.publish() failures
**Solution**: 
- Check platform event permissions
- Verify event field requirements
- Review debug logs

#### 3. Component Not Loading
**Error**: Component initialization failures
**Solution**:
- Check component permissions
- Verify object access
- Review browser console errors

#### 4. Real-time Updates Not Working
**Error**: No real-time synchronization
**Solution**:
- Check EMP API subscription
- Verify platform event channel
- Review network connectivity

### Debug Information

#### Platform Event Monitoring
```apex
// Monitor events in debug logs
System.debug('Published Event: ' + rwList);
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
```

### Performance Considerations

1. **Cache Usage**: Monitor cache memory usage
2. **Event Volume**: High-volume events may impact performance
3. **Component Lifecycle**: Ensure proper cleanup on tab close
4. **Network**: Platform events require stable network connection

### Best Practices

1. **Cache Management**: Regularly monitor cache usage
2. **Event Cleanup**: Ensure proper event cleanup on user logout
3. **Error Handling**: Implement comprehensive error handling
4. **Testing**: Run full test suite before deployment
5. **Monitoring**: Monitor platform event volume and performance

## Support

For issues and questions:
1. Check debug logs for error details
2. Verify cache partition configuration
3. Test with minimal data set
4. Review platform event limits and quotas

---

**Version**: 1.0  
**Last Updated**: 2025
**Compatibility**: Salesforce API 62.0+
