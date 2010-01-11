#define APP_ID "jp.rono23.glovepod"
#define GlovePodPreferencesChangedNotification "jp.rono23.glovepod.preferencechanged"
BOOL LSiPodVisiblePowerButtonEnabled = YES;
BOOL LSiPodVisibleVolumeButtonEnabled = YES;
BOOL LSScreenOnPowerButtonEnabled;
BOOL LSScreenOnVolumeButtonEnabled;
BOOL LSScreenOffPowerButtonEnabled;
BOOL LSScreenOffVolumeButtonEnabled;

void applyPreferences(){
    NSArray *keys = [NSArray arrayWithObjects:
        @"LSiPodVisiblePowerButtonEnabled",
        @"LSiPodVisibleVolumeButtonEnabled",
        @"LSScreenOnPowerButtonEnabled",
        @"LSScreenOnVolumeButtonEnabled",
        @"LSScreenOffPowerButtonEnabled",
        @"LSScreenOffVolumeButtonEnabled",
        nil];
    NSDictionary *dict = (NSDictionary *)CFPreferencesCopyMultiple(
        (CFArrayRef)keys,
        CFSTR(APP_ID),
        kCFPreferencesCurrentUser,
        kCFPreferencesCurrentHost);

    if(dict){
        NSArray *values = [dict objectsForKeys:keys notFoundMarker:[NSNull null]];

        id obj = [values objectAtIndex:0];
        if([obj isKindOfClass:[NSNumber class]])
            LSiPodVisiblePowerButtonEnabled = [obj boolValue];

        obj = [values objectAtIndex:1];
        if([obj isKindOfClass:[NSNumber class]])
            LSiPodVisibleVolumeButtonEnabled = [obj boolValue];

        obj = [values objectAtIndex:2];
        if([obj isKindOfClass:[NSNumber class]])
            LSScreenOnPowerButtonEnabled = [obj boolValue];

        obj = [values objectAtIndex:3];
        if([obj isKindOfClass:[NSNumber class]])
            LSScreenOnVolumeButtonEnabled = [obj boolValue];

        obj = [values objectAtIndex:4];
        if([obj isKindOfClass:[NSNumber class]])
            LSScreenOffPowerButtonEnabled = [obj boolValue];

        obj = [values objectAtIndex:5];
        if([obj isKindOfClass:[NSNumber class]])
            LSScreenOffVolumeButtonEnabled = [obj boolValue];

        [dict release];
    }
}

void reloadPreferences(){
    CFPreferencesAppSynchronize(CFSTR(APP_ID));
    applyPreferences();
}

void preferenceChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
    reloadPreferences();
}

void initPreferences(){
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        preferenceChangedCallback,
        CFSTR(GlovePodPreferencesChangedNotification),
        NULL,
        0);
    applyPreferences();
}
