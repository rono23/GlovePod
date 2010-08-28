#import <substrate.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBMediaController.h>
#import <SpringBoard/SBAwayController.h>
#import <SpringBoard/SBAwayView.h>
#import <SpringBoard/SBAwayDateView.h>
#import <SpringBoard/SBAwayMediaControlsView.h>
#import <SpringBoard/SBTelephonyManager.h>
#import <SpringBoard/VolumeControl.h>

extern BOOL LSiPodVisiblePowerButtonEnabled;
extern BOOL LSiPodVisibleVolumeButtonEnabled;
extern BOOL LSScreenOnPowerButtonEnabled;
extern BOOL LSScreenOnVolumeButtonEnabled;
extern BOOL LSScreenOffPowerButtonEnabled;
extern BOOL LSScreenOffVolumeButtonEnabled;
extern BOOL LSVolumeButtonType;
extern "C" uint32_t GSEventGetType(GSEventRef event);

static uint32_t increaseButtonID[2] = {1006, 1007};
static uint32_t decreaseButtonID[2] = {1008, 1009};
static BOOL invocationGPPowerButtonTimerDidFire = NO;
static BOOL invocationGPChangeTrackTimerDidFire = NO;
static NSTimer *invocationGPPowerButtonTimer = nil;
static NSTimer *invocationGPChangeTrackTimer = nil;
static BOOL isFirmware3x = NO;

@interface SpringBoard (firmware3x)
- (void)_unsetLockButtonBearTrap;
@end

/*==============================================================================
    ==============================================================================*/


static BOOL isLocked()
{
    return [[objc_getClass("SBAwayController") sharedAwayController] isLocked];
}

static BOOL isDimmed()
{
    return [[objc_getClass("SBAwayController") sharedAwayController] isDimmed];
}

static BOOL isVisible()
{
    return [[objc_getClass("SBAwayController") sharedAwayController] isShowingMediaControls];
}

static BOOL isPlaying()
{
    return [[objc_getClass("SBMediaController") sharedInstance] isPlaying];
}

static BOOL isCalling()
{
    return [[objc_getClass("SBTelephonyManager") sharedTelephonyManager] inCall];
}

static BOOL isPowerButtonEnabled()
{
    return ((isLocked() && !isCalling()) &&
        ((LSiPodVisiblePowerButtonEnabled && isVisible()) ||
        (LSScreenOnPowerButtonEnabled && !isDimmed() && !isVisible()) ||
        (LSScreenOffPowerButtonEnabled && isDimmed())));
}

static BOOL useDefaultVolumeAction(BOOL enabled)
{
    return (!isLocked() || (isLocked() && !isPlaying()) || !enabled);
}


/*==============================================================================
    ==============================================================================*/


static void $SpringBoard$invokeGPPowerButton(SpringBoard *self, SEL sel)
{
    invocationGPPowerButtonTimerDidFire = YES;
    [[objc_getClass("SBMediaController") sharedInstance] togglePlayPause];
}

static void startInvocationGPPowerButtonTimer()
{
    invocationGPPowerButtonTimerDidFire = NO;

    SpringBoard *springBoard = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication];
    invocationGPPowerButtonTimer = [[NSTimer scheduledTimerWithTimeInterval:0.7f
        target:springBoard selector:@selector(invokeGPPowerButton) userInfo:nil repeats:NO] retain];
}

static void cancelInvocationGPPowerButtonTimer()
{
    [invocationGPPowerButtonTimer invalidate];
    [invocationGPPowerButtonTimer release];
    invocationGPPowerButtonTimer = nil;
}


/*==============================================================================
    ==============================================================================*/


static void $SpringBoard$invokeGPChangeTrack(SpringBoard *self, SEL sel, NSTimer *aTimer)
{
    invocationGPChangeTrackTimerDidFire = NO;
    int i = [[aTimer userInfo] intValue];
    [[objc_getClass("SBMediaController") sharedInstance] changeTrack:i];
}

static void startInvocationGPChangeTrackTimer(NSString *userInfo)
{
    invocationGPChangeTrackTimerDidFire = YES;

    SpringBoard *springBoard = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication];
    invocationGPChangeTrackTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0f
        target:springBoard selector:@selector(invokeGPChangeTrack:) userInfo:userInfo repeats:YES] retain];
}

static void cancelInvocationGPChangeTrackTimer()
{
    [invocationGPChangeTrackTimer invalidate];
    [invocationGPChangeTrackTimer release];
    invocationGPChangeTrackTimer = nil;
}


/*==============================================================================
    ==============================================================================*/


static void (*_SpringBoard$lockButtonDown$)(id self, SEL cmd_, GSEventRef down) = NULL;
static void $SpringBoard$lockButtonDown$(id self, SEL cmd_, GSEventRef down)
{
    if (isPowerButtonEnabled())
        startInvocationGPPowerButtonTimer();

    _SpringBoard$lockButtonDown$(self, cmd_, down);
}

static void (*_SpringBoard$lockButtonUp$)(id self, SEL cmd_, GSEventRef up) = NULL;
static void $SpringBoard$lockButtonUp$(id self, SEL cmd_, GSEventRef up)
{
    if (invocationGPPowerButtonTimerDidFire && isPowerButtonEnabled()) {
        if (isFirmware3x)
            [self _unsetLockButtonBearTrap];

        [self _setLockButtonTimer:nil];
    } else {
        cancelInvocationGPPowerButtonTimer();
        _SpringBoard$lockButtonUp$(self, cmd_, up);
    }
}


/*==============================================================================
    ==============================================================================*/


static void nextTrack(uint32_t type)
{
    if (LSVolumeButtonType) {
        if (type == increaseButtonID[0]) {
            startInvocationGPChangeTrackTimer(@"1");
        } else if (type == increaseButtonID[1]) {
            if (invocationGPChangeTrackTimerDidFire)
                [[objc_getClass("SBMediaController") sharedInstance] changeTrack:1];
            cancelInvocationGPChangeTrackTimer();
        }
    } else {
        SBAwayMediaControlsView *view = [[[[objc_getClass("SBAwayController") sharedAwayController] awayView] dateView] controlsView];
        UIPushButton *_nextButton = MSHookIvar<UIPushButton *>(view, "_nextButton");

        if (type == increaseButtonID[0])
            [view _changeTrackButtonDown:_nextButton];

        else if (type == increaseButtonID[1])
            [view _changeTrackButtonUp:_nextButton];
    }
}

static void prevTrack(uint32_t type)
{
    if (LSVolumeButtonType) {
        if (type == decreaseButtonID[0]) {
            startInvocationGPChangeTrackTimer(@"-1");
        } else if (type == decreaseButtonID[1]) {
            if (invocationGPChangeTrackTimerDidFire)
                [[objc_getClass("SBMediaController") sharedInstance] changeTrack:-1];
            cancelInvocationGPChangeTrackTimer();
        }
    } else {
        SBAwayMediaControlsView *view = [[[[objc_getClass("SBAwayController") sharedAwayController] awayView] dateView] controlsView];
        UIPushButton *_prevButton = MSHookIvar<UIPushButton *>(view, "_prevButton");

        if (type == decreaseButtonID[0])
            [view _changeTrackButtonDown:_prevButton];

        else if (type == decreaseButtonID[1])
            [view _changeTrackButtonUp:_prevButton];
    }
}

static void hookVolumeButton(GSEventRef event)
{
    if (isLocked() && isPlaying()){
        uint32_t type = GSEventGetType(event);

        if (type == increaseButtonID[0] || type == increaseButtonID[1])
            nextTrack(type);

        if (type == decreaseButtonID[0] || type == decreaseButtonID[1])
            prevTrack(type);
    }
}


/*==============================================================================
    ==============================================================================*/


static void (*_SBMediaController$handleVolumeEvent$)(id self, SEL cmd_, GSEventRef event) = NULL;
static void $SBMediaController$handleVolumeEvent$(id self, SEL cmd_, GSEventRef event)
{
    if (LSiPodVisibleVolumeButtonEnabled)
        hookVolumeButton(event);

    _SBMediaController$handleVolumeEvent$(self, cmd_, event);
}

static void (*_SBMediaController$increaseVolume$)(id self, SEL cmd_) = NULL;
static void $SBMediaController$increaseVolume$(id self, SEL cmd_)
{
    if (useDefaultVolumeAction(LSiPodVisibleVolumeButtonEnabled))
        _SBMediaController$increaseVolume$(self, cmd_);
}

static void (*_SBMediaController$decreaseVolume$)(id self, SEL cmd_) = NULL;
static void $SBMediaController$decreaseVolume$(id self, SEL cmd_)
{
    if (useDefaultVolumeAction(LSiPodVisibleVolumeButtonEnabled))
        _SBMediaController$decreaseVolume$(self, cmd_);
}


/*==============================================================================
    ==============================================================================*/


static void (*_VolumeControl$handleVolumeEvent$)(id self, SEL cmd_, GSEventRef event) = NULL;
static void $VolumeControl$handleVolumeEvent$(id self, SEL cmd_, GSEventRef event)
{
    if ((!isDimmed() && LSScreenOnVolumeButtonEnabled) || (isDimmed() && LSScreenOffVolumeButtonEnabled))
        hookVolumeButton(event);

    _VolumeControl$handleVolumeEvent$(self, cmd_, event);
}

static void (*_VolumeControl$increaseVolume$)(id self, SEL cmd_) = NULL;
static void $VolumeControl$increaseVolume$(id self, SEL cmd_)
{
    if ((!isDimmed() && useDefaultVolumeAction(LSScreenOnVolumeButtonEnabled)) || (isDimmed() && useDefaultVolumeAction(LSScreenOffVolumeButtonEnabled)))
        _VolumeControl$increaseVolume$(self, cmd_);
}

static void (*_VolumeControl$decreaseVolume$)(id self, SEL cmd_) = NULL;
static void $VolumeControl$decreaseVolume$(id self, SEL cmd_)
{
    if ((!isDimmed() && useDefaultVolumeAction(LSScreenOnVolumeButtonEnabled)) || (isDimmed() && useDefaultVolumeAction(LSScreenOffVolumeButtonEnabled)))
        _VolumeControl$decreaseVolume$(self, cmd_);
}


/*==============================================================================
    ==============================================================================*/


void initGlovePod()
{
    isFirmware3x = [[[UIDevice currentDevice] systemVersion] hasPrefix:@"3"];

    Class $SpringBoard(objc_getClass("SpringBoard"));
    class_addMethod($SpringBoard, @selector(invokeGPPowerButton), (IMP)&$SpringBoard$invokeGPPowerButton, "v@:");
    class_addMethod($SpringBoard, @selector(invokeGPChangeTrack:), (IMP)&$SpringBoard$invokeGPChangeTrack, "v@:");
    _SpringBoard$lockButtonUp$ = MSHookMessage($SpringBoard, @selector(lockButtonUp:), &$SpringBoard$lockButtonUp$);
    _SpringBoard$lockButtonDown$ = MSHookMessage($SpringBoard, @selector(lockButtonDown:), &$SpringBoard$lockButtonDown$);

    Class $SBMediaController(objc_getClass("SBMediaController"));
    _SBMediaController$increaseVolume$ = MSHookMessage($SBMediaController, @selector(increaseVolume), &$SBMediaController$increaseVolume$);
    _SBMediaController$decreaseVolume$ = MSHookMessage($SBMediaController, @selector(decreaseVolume), &$SBMediaController$decreaseVolume$);
    _SBMediaController$handleVolumeEvent$ = MSHookMessage($SBMediaController, @selector(handleVolumeEvent:), &$SBMediaController$handleVolumeEvent$);

    Class $VolumeControl(objc_getClass("VolumeControl"));
    _VolumeControl$increaseVolume$ = MSHookMessage($VolumeControl, @selector(increaseVolume), &$VolumeControl$increaseVolume$);
    _VolumeControl$decreaseVolume$ = MSHookMessage($VolumeControl, @selector(decreaseVolume), &$VolumeControl$decreaseVolume$);
    _VolumeControl$handleVolumeEvent$ = MSHookMessage($VolumeControl, @selector(handleVolumeEvent:), &$VolumeControl$handleVolumeEvent$);
}
