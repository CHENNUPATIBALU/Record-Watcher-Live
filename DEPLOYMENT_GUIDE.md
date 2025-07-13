# RecordWatcher Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Deployment Methods](#deployment-methods)
4. [Configuration](#configuration)
5. [Post-Deployment Setup](#post-deployment-setup)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements
- **Salesforce Org**: API version 62.0 or higher
- **Lightning Experience**: Must be enabled
- **Platform Cache**: Must be enabled and configured
- **User Permissions**: Read access to User object, platform event access

### Required Permissions
- **Profile**: System Administrator or Customize Application
- **Permission Sets**: None required (uses standard permissions)
- **Object Access**: Read access to User object
- **Platform Events**: Access to publish and subscribe to platform events

### Development Tools
- **Salesforce CLI**: Latest version
- **VS Code**: With Salesforce extensions (recommended)
- **Git**: For version control

## Environment Setup

### 1. Development Environment

#### Clone Repository
```bash
git clone <repository-url>
cd RecordWatcher
```

#### Authenticate with Salesforce
```bash
# For production org
sfdx auth:web:login -a ProductionOrg

# For sandbox
sfdx auth:web:login -a SandboxOrg -r https://test.salesforce.com

# For scratch org
sfdx force:org:create -f config/project-scratch-def.json -a RecordWatcher
```

#### Verify Connection
```bash
sfdx force:org:display -u RecordWatcher
```

### 2. Platform Cache Configuration

#### Check Current Cache Configuration
```bash
# Query cache partitions
sfdx force:data:soql:query -q "SELECT Id, Name, MasterLabel, NamespacePrefix FROM CachePartition"
```

#### Create Cache Partition (if needed)
```bash
# Create cache partition metadata
mkdir -p force-app/main/default/cachePartitions/RecordWatcher
```

Create `force-app/main/default/cachePartitions/RecordWatcher/RecordWatcher.cachePartition-meta.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CachePartition xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Cache partition for RecordWatcher application</description>
    <isDefaultPartition>true</isDefaultPartition>
    <masterLabel>RecordWatcher</masterLabel>
    <note>Default partition for RecordWatcher cache operations</note>
    <partitionType>Default</partitionType>
    <platformCacheType>Session</platformCacheType>
    <platformCacheType>Org</platformCacheType>
</CachePartition>
```

## Deployment Methods

### Method 1: Salesforce CLI (Recommended)

#### Deploy All Components
```bash
# Deploy entire project
sfdx force:source:deploy -p force-app/main/default

# Deploy with test execution
sfdx force:source:deploy -p force-app/main/default --testlevel RunLocalTests

# Deploy with specific test classes
sfdx force:source:deploy -p force-app/main/default --testlevel RunSpecifiedTests --runtests RecordWatcherControllerTest,RecordWatcherEventTriggerTest
```

#### Deploy Specific Components
```bash
# Deploy only Apex classes
sfdx force:source:deploy -p force-app/main/default/classes

# Deploy only components
sfdx force:source:deploy -p force-app/main/default/aura,force-app/main/default/lwc

# Deploy only triggers
sfdx force:source:deploy -p force-app/main/default/triggers

# Deploy only custom objects
sfdx force:source:deploy -p force-app/main/default/objects
```

#### Validate Deployment
```bash
# Validate without deploying
sfdx force:source:deploy -p force-app/main/default --checkonly

# Validate with test execution
sfdx force:source:deploy -p force-app/main/default --checkonly --testlevel RunLocalTests
```

### Method 2: Change Set Deployment

#### Create Change Set
1. Navigate to Setup → Deployment → Outbound Change Sets
2. Create new change set named "RecordWatcher"
3. Add components:
   - **Apex Classes**: RecordWatcherController, ObjectsDynamicPicklistDesignAttr
   - **Apex Triggers**: RecordWatcherEventTrigger, RecordWatcherLogoutEventTrg
   - **Custom Objects**: Record_Watcher__e
   - **Aura Components**: RecordWatcher, showToast
   - **LWC Components**: recordWatcherLWC, recordWatchersModal, etc.
   - **Cache Partitions**: RecordWatcher

#### Upload Change Set
1. Upload change set to target org
2. Deploy change set in target org
3. Activate components

### Method 3: Metadata API Deployment

#### Create Package.xml
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
    <types>
        <members>RecordWatcher</members>
        <members>showToast</members>
        <name>AuraDefinitionBundle</name>
    </types>
    <types>
        <members>recordWatcherLWC</members>
        <members>recordWatchersModal</members>
        <members>recordWatcherObjectsList</members>
        <members>recordWatchersAgentForce</members>
        <members>recordWatcherTab</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>RecordWatcher</members>
        <name>CachePartition</name>
    </types>
    <version>62.0</version>
</Package>
```

#### Deploy via Metadata API
```bash
# Retrieve metadata
sfdx force:source:retrieve -m ApexClass,Trigger,CustomObject,AuraDefinitionBundle,LightningComponentBundle,CachePartition

# Deploy metadata
sfdx force:source:deploy -m ApexClass,Trigger,CustomObject,AuraDefinitionBundle,LightningComponentBundle,CachePartition
```

## Configuration

### 1. Platform Cache Setup

#### Configure Default Partition
1. Navigate to Setup → Platform Cache
2. Create new partition or designate existing as default
3. Allocate sufficient memory (recommended: 10MB minimum)
4. Set partition as default

#### Verify Cache Configuration
```apex
// Test cache access
Boolean hasCache = RecordWatcherController.checkDefaultCachePartition();
System.debug('Cache available: ' + hasCache);
```

### 2. Platform Events Configuration

#### Verify Platform Event Permissions
1. Navigate to Setup → Platform Events
2. Verify Record_Watcher__e event is visible
3. Check user permissions for platform events

#### Test Platform Event Publishing
```apex
// Test event publishing
Record_Watcher__e testEvent = new Record_Watcher__e();
testEvent.Record_Id__c = '001XXXXXXXXXXXXXXX';
testEvent.sObjectName__c = 'Account';
testEvent.User_Id__c = UserInfo.getUserId();
testEvent.Is_Watching__c = true;

EventBus.publish(testEvent);
```

### 3. Component Configuration

#### Add Components to Record Pages
1. Navigate to Setup → Object Manager
2. Select target object (e.g., Account)
3. Click "Lightning Record Pages"
4. Edit the record page
5. Add RecordWatcher component
6. Configure component properties:
   - **Object**: Select target object
7. Save and activate

#### Component Properties
```xml
<!-- Aura Component -->
<c:RecordWatcher recordId="{!v.recordId}" sObjectName="{!v.sObjectName}" />

## Post-Deployment Setup

### 1. Verify Deployment

#### Check Component Deployment
```bash
# List deployed components
sfdx force:source:retrieve -m ApexClass,Trigger,CustomObject,AuraDefinitionBundle,LightningComponentBundle

# Verify component visibility
sfdx force:data:soql:query -q "SELECT Id, Name, MasterLabel FROM ApexClass WHERE Name LIKE 'RecordWatcher%'"
```

#### Test Component Functionality
1. Open any record page
2. Verify RecordWatcher component loads
3. Check browser console for errors
4. Test platform event subscription

### 2. User Training

#### Admin Training
- Component configuration
- Cache monitoring
- Event troubleshooting
- Performance monitoring

#### End User Training
- Understanding watcher indicators
- Real-time collaboration features
- Tab management
- User interface navigation

### 3. Monitoring Setup

#### Debug Logs
1. Setup → Debug Logs
2. Create new debug log
3. Set trace flags for monitoring
4. Configure log levels

#### Platform Event Monitoring
```apex
// Monitor event volume
SELECT COUNT(Id), DATE(CreatedDate) 
FROM Record_Watcher__e 
WHERE CreatedDate = TODAY 
GROUP BY DATE(CreatedDate)
```

#### Cache Monitoring
```apex
// Monitor cache usage
Set<String> cacheKeys = Cache.Org.getKeys();
System.debug('Active cache keys: ' + cacheKeys.size());
```

## Troubleshooting

### Common Deployment Issues

#### 1. Platform Cache Not Configured
**Error**: "A default partition was not found"
**Solution**:
```bash
# Check cache partitions
sfdx force:data:soql:query -q "SELECT Id, Name, MasterLabel, IsDefaultPartition FROM CachePartition"

# Create default partition if needed
sfdx force:source:deploy -p force-app/main/default/cachePartitions
```

#### 2. Component Not Visible
**Error**: Component not appearing in Lightning App Builder
**Solution**:
1. Check component metadata
2. Verify component targets
3. Check user permissions
4. Clear browser cache

#### 3. Platform Event Permissions
**Error**: "Insufficient access rights on cross-reference id"
**Solution**:
1. Check user profile permissions
2. Verify platform event access
3. Check object permissions

### Debug Commands

#### Check Component Status
```bash
# List all components
sfdx force:source:retrieve -m AuraDefinitionBundle,LightningComponentBundle

# Check component metadata
sfdx force:source:retrieve -p force-app/main/default/aura/RecordWatcher
```

#### Monitor Platform Events
```bash
# Query recent events
sfdx force:data:soql:query -q "SELECT Id, Record_Id__c, sObjectName__c, User_Id__c, Is_Watching__c, CreatedDate FROM Record_Watcher__e ORDER BY CreatedDate DESC LIMIT 10"
```

#### Check Cache Status
```apex
// Debug cache operations
Boolean hasCache = RecordWatcherController.checkDefaultCachePartition();
System.debug('Cache available: ' + hasCache);

Set<String> cacheKeys = Cache.Org.getKeys();
System.debug('Cache keys: ' + cacheKeys);
```

### Performance Optimization

#### Cache Optimization
```apex
// Monitor cache usage
Set<String> cacheKeys = Cache.Org.getKeys();
System.debug('Cache keys count: ' + cacheKeys.size());

// Clean up old cache entries
for (String key : cacheKeys) {
    if (key.startsWith('RW')) {
        Object cachedData = Cache.Org.get(key);
        // Check if data is stale and remove if needed
    }
}
```

#### Event Optimization
```apex
// Monitor event volume
Integer eventCount = Limits.getPublishImmediateDML();
System.debug('Events published: ' + eventCount);

// Batch event publishing
List<Record_Watcher__e> events = new List<Record_Watcher__e>();
// Add events to list
EventBus.publish(events);
```

### Rollback Procedures

#### Rollback Deployment
```bash
# Deploy previous version
sfdx force:source:deploy -p force-app/main/default --checkonly

# Remove components
sfdx force:source:delete -p force-app/main/default/classes/RecordWatcherController.cls
sfdx force:source:delete -p force-app/main/default/triggers/RecordWatcherEventTrigger.trigger
```

#### Data Cleanup
```apex
// Clean up cache
Set<String> cacheKeys = Cache.Org.getKeys();
for (String key : cacheKeys) {
    if (key.startsWith('RW')) {
        Cache.Org.remove(key);
    }
}

// Clean up platform events (if needed)
DELETE FROM Record_Watcher__e WHERE CreatedDate < TODAY
```

---

**Note**: This deployment guide provides comprehensive instructions for deploying the RecordWatcher application. For additional support, refer to the main README.md and DEVELOPER_GUIDE.md files. 