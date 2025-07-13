({
    doInit: function (component, event, helper) {
        var checkDefaultCachePartition = component.get('c.checkDefaultCachePartition');
        checkDefaultCachePartition.setCallback(this, function (res) {
            var state = res.getState();
            if (state == 'SUCCESS') {
                var response = res.getReturnValue();
                console.log('Has Default Cache', response);
                if (response) {
                    console.log('Subscribing to the PE', response);
                    var userId = $A.get("$SObjectType.CurrentUser.Id");
                    component.set('v.currentUserId', userId);

                    // Subscribing to event
                    var subscribeEvent = component.get('c.subscribe');
                    $A.enqueueAction(subscribeEvent);

                    const empApi = component.find('empApi');

                    // Uncomment below line to enable debug logging (optional)
                    // empApi.setDebugFlag(true);

                    // Register error listener and pass in the error handler function
                    empApi.onError($A.getCallback(error => {
                        console.error('EMP API error: ', JSON.stringify(error));
                    }));
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": "A default partition was not found.  To cache without partition reference, designate a partition as default."
                    });
                    toastEvent.fire();
                    component.set('v.ErrorMsg', 'A default partition was not found.  To cache without partition reference, designate a partition as default.');
                    component.set('v.hasError', true);
                }
            } else {
                console.log('Error in fetching default Cache', state, res.getError());
                component.set('v.ErrorMsg', res.getError());
                component.set('v.hasError', true);
            }
        });
        $A.enqueueAction(checkDefaultCachePartition);
    },

    getAllTabInfo: function (component, event, helper) {
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        component.set('v.currentUserId', userId);
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getAllTabInfo().then(function (response) {
            console.log(response);
            component.set('v.openedTabs', JSON.stringify(response), response);
            if (response != null && response.length > 0) {
                response.forEach(tab => {
                    console.log('Tab=' + JSON.stringify(tab));
                    //For Tabs
                    var recId = tab.recordId;
                    if (tab.focused) {
                        component.set('v.updateRecId', recId);
                        component.set('v.currentTabId', tab.tabId);
                        console.log('Focused Tab-' + recId);
                        var recordWorker = component.get('c.getRecordWatcher');
                        recordWorker.setParams({
                            recId: component.get('v.updateRecId'),
                            objApiName: component.get('v.sObjectName'),
                            keyParam: null
                        });
                        recordWorker.setCallback(this, function (res) {
                            var state = res.getState();
                            console.log('State=', state);
                            if (state === "SUCCESS") {
                                var storeResponse = res.getReturnValue();
                                console.log('Record Worker=', storeResponse);
                                var updateTab = component.get('c.updateRecordRelatedToTab');
                                $A.enqueueAction(updateTab);
                            }
                        });
                        $A.enqueueAction(recordWorker);

                    } else {
                        // For subtabs
                        var subtabs = tab.subtabs;
                        if (subtabs != null && subtabs.length > 0) {
                            subtabs.forEach(subtab => {
                                recId = subtab.recordId;
                                component.set('v.updateRecId', recId);
                                if (subtab.focused) {
                                    var recordWorker = component.get('c.getRecordWatcher');
                                    recordWorker.setParams({
                                        recId: component.get('v.updateRecId'),
                                        objApiName: component.get('v.sObjectName'),
                                        keyParam: null
                                    });
                                    recordWorker.setCallback(this, function (res) {
                                        var state = res.getState();
                                        if (state === "SUCCESS") {
                                            var storeResponse = res.getReturnValue();
                                            console.log(storeResponse);
                                            var updateTab = component.get('c.updateRecordRelatedToTab');
                                            $A.enqueueAction(updateTab);
                                        }
                                    });
                                    $A.enqueueAction(recordWorker);
                                }
                            });
                        }
                    }
                });
            }
        })
            .catch(function (error) {
                console.log(error);
                component.set('v.isWorking', false);
            });
    },

    updateRecordRelatedToTab: function (component, event, helper) {
        var recId = component.get('v.updateRecId');
        var sObjName = component.get('v.sObjectName');
        var userId = component.get('v.currentUserId');

        // Check if user is already in the org cache
        var checkUserInCache = component.get('c.isUserInRecordWatcherCache');
        checkUserInCache.setParams({
            userId: userId,
            recordId: recId,
            objectApiName: sObjName
        });
        checkUserInCache.setCallback(this, function(res) {
            var state = res.getState();
            if (state === 'SUCCESS') {
                var isInCache = res.getReturnValue();
                console.log('Received isInCache',isInCache);
                if (!isInCache) {
                    // Only update if user is not in cache
                    var updateRecordTab = component.get('c.updateRecordWatcher');
                    updateRecordTab.setParams({
                        recordId: recId,
                        sObjType: sObjName,
                        userId: userId,
                        isWatching: true
                    });
                    updateRecordTab.setCallback(this, function (res) {
                        var state = res.getState();
                        if (state == 'SUCCESS') {
                            var response = res.getReturnValue();
                            console.log('Update record tab res=', response);
                            if (response != null) {
                                console.log('Updated Record=', response);
                                console.log(response);
                            }
                        } else {
                            console.log('Updated Record Tab error=', state, res.getError());
                        }
                    });
                    $A.enqueueAction(updateRecordTab);
                } else {
                    console.log('User is already in the org cache, skipping updateRecordTab');
                }
            } else {
                console.log('Error checking user in org cache', state, res.getError());
            }
        });
        $A.enqueueAction(checkUserInCache);

        var recordWorker = component.get('c.getRecordWatcher');
        recordWorker.setParams({
            recId: component.get('v.updateRecId'),
            objApiName: component.get('v.sObjectName'),
            keyParam: null
        });
        recordWorker.setCallback(this, function (res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                var storeResponse = res.getReturnValue();
                console.log('Get Record Watcher::', storeResponse);
                if (storeResponse == null || storeResponse == '') {
                    component.set('v.isWorking', false);
                } else {
                    console.log('Record Worker Updated res=', storeResponse);
                    var refreshTab = component.get('c.refresh');
                    $A.enqueueAction(refreshTab);
                }
            } else {
                console.log('Record Worker Tab error=', state, res.getError());
            }
        });
        $A.enqueueAction(recordWorker);
    },
    handleDestroy: function (cmp, evt, h) {
        window.removeEventListener('beforeunload', function (event) {
            // Remove the event listener
        });
    },
    onTabClosed: function (component, event, helper) {
        console.log('Closed Tab=', event.getParams(),event.getParam('tabId') == component.get('v.currentTabId'));
        //console.log('Opened Tabs=',component.get('v.openedTabs'));
        if (event.getParam('tabId') == component.get('v.currentTabId')) {
            console.log('Inside IF-200');
            var updateTab = component.get('c.removeRecordWatcherOrgCache');
            updateTab.setParams({
                recordId: component.get('v.updateRecId'),
                objectApiName: component.get('v.sObjectName'),
                userId: component.get('v.currentUserId'),
                keyParam: null
            });
            updateTab.setCallback(this, function (res) {
                var state = res.getState();
                console.log('State=',state);
                if (state === "SUCCESS") {
                    var storeResponse = res.getReturnValue();
                    console.log('Removed Watcher=', storeResponse);
                    window.clearInterval(component.get('v.setIntervalId'));
                    component.set('v.setIntervalId', null);
                }else{
                    console.log('Error in removing Record Watcher', res.getError());
                }
            });
            $A.enqueueAction(updateTab);
            component.set('v.currentUserId', null);
        }

    },

    onTabRefreshed : function(component, event, helper) {
        var refreshedTabId = event.getParam("tabId");
        if (refreshedTabId == component.get('v.currentTabId')) {
            var updateTab = component.get('c.updateRecordRelatedToTab');
            $A.enqueueAction(updateTab);
        }
    },

    onTabFocused : function(component, event, helper) {
        var focusedTabId = event.getParam('currentTabId');
        var workspaceAPI = component.find("workspace");

        console.log('On Tab Focused',focusedTabId);
        var userId = component.get('v.currentUserId');

        var recordWorker = component.get('c.getRecordWatcher');
        recordWorker.setParams({
            recId: component.get('v.updateRecId'),
            objApiName: component.get('v.sObjectName'),
            keyParam: null
        });
        recordWorker.setCallback(this, function (res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                var storeResponse = res.getReturnValue();
                console.log('Get Record Watcher Tab::', storeResponse);
                if (storeResponse == null || storeResponse == '') {
                    component.set('v.isWorking', false);
                } else {
                    console.log('Record Worker Updated res=', storeResponse);
                    var workersMap = storeResponse.userIdActivityMap;
                    console.log(component.get('v.updateRecId'),'Workers Map=', workersMap);
                    
                    workspaceAPI.getAllTabInfo().then(function (response) {
                        for (let record of response) {
                            console.log('TabRes=', record);
                            if(!record.focused){
                                console.log(record.recordId, 'Tab is not focused');
                               // if(workersMap[userId]){
                                    let recordId = record.recordId;
                                    var updateRecordTab = component.get('c.updateRecordWatcher');
                                    updateRecordTab.setParams({
                                        recordId: recordId,
                                        sObjType: null,
                                        userId: userId,
                                        isWatching: false
                                    });
                                    updateRecordTab.setCallback(this, function (res) {
                                        var state = res.getState();
                                        if (state == 'SUCCESS') {
                                            var response = res.getReturnValue();
                                            console.log('Update record tab res=', response);
                                            if (response != null) {
                                                console.log('Updated Unfocused Record=', response);
                                                console.log(response);
                                            }
                                        } else {
                                            console.log('Updated Record Tab error=', state, res.getError());
                                        }
                                    });
                                    $A.enqueueAction(updateRecordTab);
                                //}
            
                                var subtabs = record.subtabs;
                                if (subtabs != null && subtabs.length > 0) {
                                    subtabs.forEach(subtab => {
                                        let recId = subtab.recordId;
                                        if (subtab.focused) {
                                           // if(!workersMap[userId]){
                                                var updateRecordTab = component.get('c.updateRecordWatcher');
                                                updateRecordTab.setParams({
                                                    recordId: recId,
                                                    sObjType: null,
                                                    userId: userId,
                                                    isWatching: true
                                                });
                                                updateRecordTab.setCallback(this, function (res) {
                                                    var state = res.getState();
                                                    if (state == 'SUCCESS') {
                                                        var response = res.getReturnValue();
                                                        console.log('Update record tab res=', response);
                                                        if (response != null) {
                                                            console.log('Updated Subtab Focused Record=', response);
                                                            console.log(response);
                                                        }
                                                    } else {
                                                        console.log('Updated Record Tab error=', state, res.getError());
                                                    }
                                                });
                                                $A.enqueueAction(updateRecordTab);
                                            //}
                                            
                                        }else{
                                           // if(workersMap[userId]){
                                                var updateRecordTab = component.get('c.updateRecordWatcher');
                                                updateRecordTab.setParams({
                                                    recordId: recId,
                                                    sObjType: null,
                                                    userId: userId,
                                                    isWatching: false
                                                });
                                                updateRecordTab.setCallback(this, function (res) {
                                                    var state = res.getState();
                                                    if (state == 'SUCCESS') {
                                                        var response = res.getReturnValue();
                                                        console.log('Update record tab res=', response);
                                                        if (response != null) {
                                                            console.log('Updated Subtab Unfocused Record=', response);
                                                            console.log(response);
                                                        }
                                                    } else {
                                                        console.log('Updated Record Tab error=', state, res.getError());
                                                    }
                                                });
                                                $A.enqueueAction(updateRecordTab);
                                           // }
                                        }
                                    });
                                }
                            }else{
                                //if(!workersMap[userId]){
                                    let recordId = record.recordId;
                                    var updateRecordTab = component.get('c.updateRecordWatcher');
                                    updateRecordTab.setParams({
                                        recordId: recordId,
                                        sObjType: null,
                                        userId: userId,
                                        isWatching: true
                                    });
                                    updateRecordTab.setCallback(this, function (res) {
                                        var state = res.getState();
                                        if (state == 'SUCCESS') {
                                            var response = res.getReturnValue();
                                            console.log('Update record tab res=', response);
                                            if (response != null) {
                                                console.log('Updated Focused Record=', response);
                                                console.log(response);
                                            }
                                        } else {
                                            console.log('Updated Record Tab error=', state, res.getError());
                                        }
                                    });
                                    $A.enqueueAction(updateRecordTab);
                                //}
                                
                            }
                        }
                        });
                    
                }
            } else {
                console.log('Record Worker Tab error=', state, res.getError());
            }
        });
        $A.enqueueAction(recordWorker);
    },

    refresh: function (component, event, helper) {
        var recordWorker = component.get('c.getRecordWatcher');
        recordWorker.setParams({
            recId: component.get('v.recordId'),
            objApiName: component.get('v.sObjectName'),
            keyParam: null
        });
        recordWorker.setCallback(this, function (res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                var storeResponse = res.getReturnValue();
                console.log('Watchers=', storeResponse);
                if (storeResponse == null || storeResponse == '') {
                    component.set('v.isWorking', false);
                } else {
                    console.log('Record Worker Updated res=', storeResponse);
                    var workersMap = storeResponse.userIdActivityMap;
                    console.log('Workers Map=', workersMap);
                    var workers = Object.keys(workersMap);
                    var currentUsers = component.get('v.workers');
                    console.log('Workers=', JSON.stringify(currentUsers));
                    var action = component.get("c.fetchUser");
                    var ids = [];
                    if (currentUsers != null && currentUsers.length > 0) {
                        currentUsers.forEach(u => {
                            ids.push(u.Id);
                        });
                        if (JSON.stringify(ids) != JSON.stringify(workers)) {
                            console.log('New Workers=', workers);
                            action.setParams({
                                userId: workers
                            });
                            $A.enqueueAction(action);
                        }
                    } else {
                        console.log('New Workers=', JSON.stringify(workers));
                        action.setParams({
                            userId: workers
                        });
                        $A.enqueueAction(action);
                    }

                    action.setCallback(this, function (response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {
                            var storeResponse = response.getReturnValue();
                            console.log(storeResponse);
                            if (storeResponse != null && storeResponse.length > 0) {
                                var workersExceptCurrentUser = [];
                                storeResponse.forEach(w => {
                                    if (w.Id != component.get("v.currentUserId")) {
                                        console.log('RecordWorker=', w);
                                        workersExceptCurrentUser.push(w);
                                    }
                                });
                                if (workersExceptCurrentUser.length > 0) {
                                    if (JSON.stringify(workersExceptCurrentUser) != JSON.stringify(component.get('v.oldWorkers'))) {
                                        console.log('New worker added=', workersExceptCurrentUser);
                                        
                                        if(component.get('v.isTesting')){
                                            var testWorkers = [
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 1 - Active', SmallPhotoUrl: 'https://example.com/photo1.jpg', isActive: true, customCss: 'cursor: pointer;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 2 - Inactive', SmallPhotoUrl: 'https://example.com/photo2.jpg', isActive: false, customCss: 'cursor: pointer; opacity: 0.5; transition: opacity 0.3s ease;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 3 - Active', SmallPhotoUrl: 'https://example.com/photo3.jpg', isActive: true, customCss: 'cursor: pointer;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 4 - Inactive', SmallPhotoUrl: 'https://example.com/photo4.jpg', isActive: false, customCss: 'cursor: pointer; opacity: 0.5; transition: opacity 0.3s ease;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 5 - Active', SmallPhotoUrl: 'https://example.com/photo5.jpg', isActive: true, customCss: 'cursor: pointer;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 6 - Inactive', SmallPhotoUrl: 'https://example.com/photo6.jpg', isActive: false, customCss: 'cursor: pointer; opacity: 0.5; transition: opacity 0.3s ease;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 7 - Active', SmallPhotoUrl: 'https://example.com/photo7.jpg', isActive: true, customCss: 'cursor: pointer;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 8 - Inactive', SmallPhotoUrl: 'https://example.com/photo8.jpg', isActive: false, customCss: 'cursor: pointer; opacity: 0.5; transition: opacity 0.3s ease;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 9 - Active', SmallPhotoUrl: 'https://example.com/photo9.jpg', isActive: true, customCss: 'cursor: pointer;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 10 - Inactive', SmallPhotoUrl: 'https://example.com/photo10.jpg', isActive: false, customCss: 'cursor: pointer; opacity: 0.5; transition: opacity 0.3s ease;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 11 - Active', SmallPhotoUrl: 'https://example.com/photo10.jpg', isActive: true, customCss: 'cursor: pointer;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 12 - Inactive', SmallPhotoUrl: 'https://example.com/photo12.jpg', isActive: false, customCss: 'cursor: pointer; opacity: 0.5; transition: opacity 0.3s ease;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 13 - Active', SmallPhotoUrl: 'https://example.com/photo13.jpg', isActive: true, customCss: 'cursor: pointer;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 14 - Inactive', SmallPhotoUrl: 'https://example.com/photo14.jpg', isActive: false, customCss: 'cursor: pointer; opacity: 0.5; transition: opacity 0.3s ease;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 15 - Active', SmallPhotoUrl: 'https://example.com/photo15.jpg', isActive: true, customCss: 'cursor: pointer;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 16 - Inactive', SmallPhotoUrl: 'https://example.com/photo16.jpg', isActive: false, customCss: 'cursor: pointer; opacity: 0.5; transition: opacity 0.3s ease;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 17 - Active', SmallPhotoUrl: 'https://example.com/photo17.jpg', isActive: true, customCss: 'cursor: pointer;'},
                                                {Id: '005IT00000DZ3ZJYA1', Name: 'Test Worker 18 - Inactive', SmallPhotoUrl: 'https://example.com/photo10.jpg', isActive: false, customCss: 'cursor: pointer; opacity: 0.5; transition: opacity 0.3s ease;'}
                                            ];
                                            
                                            component.set('v.workers', testWorkers);
                                        }else{
                                            var workersExceptCurrentUserMap = [];

                                            workersExceptCurrentUser.forEach(w => {
                                                var worker = Object.assign({},w);
                                                worker.isActive = workersMap[w.Id];
                                                worker.Name = worker.Name +' - '+((worker.isActive)?'Active':'Inactive');
                                                worker.customCss = (!worker.isActive) ? 'cursor: pointer; opacity: 0.5; transition: opacity 0.3s ease;' : 'cursor: pointer;';
                                                workersExceptCurrentUserMap.push(worker);

                                            });
                                            component.set('v.workers', workersExceptCurrentUserMap);
                                            console.log('Workers===>',JSON.stringify(component.get('v.workers')));
                                        }
                                        
                                        component.set('v.workersCount', component.get('v.workers').length);
                                    }

                                    component.set('v.isWorking', true);
                                } else {
                                    component.set('v.isWorking', false);
                                }
                            }

                        } else {
                            console.log('Fetch User Error in PE Subscribe=', state, response.getError());
                        }
                    });
                }
            } else {
                console.log('Updated Record Tab error=', state, res.getError());
            }
        });
        $A.enqueueAction(recordWorker);
    },

    // Invokes the subscribe method on the empApi component
    subscribe: function (component, event, helper) {
        const empApi = component.find('empApi');
        const channel = component.find('channel').get('v.value');
        const replayId = -1;

        // Subscribe to an event
        empApi.subscribe(channel, replayId, $A.getCallback(eventReceived => {
            console.log('Received event ', JSON.stringify(eventReceived));
            if (eventReceived.data.payload.sObjectName__c == component.get('v.sObjectName')) {
                console.log('Current RecordId=', component.get('v.updateRecId'));
                console.log('RecordId matches with Current Opened Tab=', (eventReceived.data.payload.Record_Id__c == component.get('v.updateRecId')));

                if (eventReceived.data.payload.Record_Id__c == component.get('v.updateRecId')) {
                    var refreshWorkers = component.get('c.refresh');
                    $A.enqueueAction(refreshWorkers);
                }

            }
            else {
                component.set('v.isWorking', false);
            }
        }))
            .then(subscription => {
                console.log('Subscription request sent to: ', subscription.channel);
                var getAllTabsInfo = component.get('c.getAllTabInfo');
                getAllTabsInfo.setCallback(this, function (res) {
                    var state = res.getState();

                    if (state == 'SUCCESS') {
                        console.log('User subscribed to this record updates and user added to the list=', state);
                        var intervalId = window.setInterval(
                            $A.getCallback(function() { 
                                var updateTab = component.get('c.updateRecordRelatedToTab');
                                $A.enqueueAction(updateTab);
                            }), 5000
                        );
                        component.set('v.setIntervalId', intervalId);
                    } else {
                        console.log('User not added to the list=', state, res.getError());
                    }
                });
                component.set('v.oldWorkers', component.get('v.workers'));
                $A.enqueueAction(getAllTabsInfo);
                component.set('v.subscription', subscription);
            });
    },

    // Invokes the unsubscribe method on the empApi component
    unsubscribe: function (component, event, helper) {
        const empApi = component.find('empApi');
        const subscription = component.get('v.subscription');

        // Unsubscribe from event
        empApi.unsubscribe(subscription, $A.getCallback(unsubscribed => {
            console.log('Unsubscribed from channel ' + unsubscribed.subscription);
            component.set('v.subscription', null);
        }));
    },

    // Show more watchers overlay
    showMoreWatchers: function (component, event, helper) {
        console.log('Show more watchers');
        var workers = component.get('v.workers');
        console.log('Workers=', JSON.stringify(workers), JSON.stringify(component.get('v.workers').length));
        var moreWatchers = workers.slice(5);
        console.log('More watchers=', JSON.stringify(moreWatchers));
        component.set('v.showWatchersModal', true);
    },

    // Hide more watchers overlay
    hideMoreWatchers: function (component, event, helper) {
        component.set('v.showWatchersModal', false);
    },

    openUserDetail: function (component, event, helper) {
        var userId = null;
        if(event.getParam('userId')!=null){
            userId = event.getParam('userId');
            $A.enqueueAction(component.get('c.hideMoreWatchers'));
        }else{
            userId = event.target.dataset.userId;
        }
        console.log('UserId=', userId);
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": userId,
            "slideDevName": "detail"
        });
        navEvt.fire();
    }
})