#import <substrate.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBMediaController.h>
#import <SpringBoard/SBAwayController.h>
#import <SpringBoard/SBAwayView.h>
#import <SpringBoard/SBAwayDateView.h>
#import <SpringBoard/SBAwayMediaControlsView.h>

extern "C" uint32_t GSEventGetType(GSEventRef event);
static unsigned int increaseButtonID[2] = {1006, 1007};
static unsigned int decreaseButtonID[2] = {1008, 1009};
static NSTimer *invocationGlovePodTimer = nil;

static BOOL isShowing(){
  return [[objc_getClass("SBAwayController") sharedAwayController] isShowingMediaControls];
}

static void $SpringBoard$invokeGlovePod(SpringBoard *self, SEL sel)
{
  if(isShowing())
    [[objc_getClass("SBMediaController") sharedInstance] togglePlayPause];
}

static void startInvocationGloveTimer()
{
  SpringBoard *springBoard = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication];
  invocationGlovePodTimer = [[NSTimer scheduledTimerWithTimeInterval:0.7f
    target:springBoard selector:@selector(invokeGlovePod) userInfo:nil repeats:NO] retain];
}

static void cancelInvocationGloveTimer()
{
  [invocationGlovePodTimer invalidate];
  [invocationGlovePodTimer release];
  invocationGlovePodTimer = nil;
}

static void hookIncreaseVolume(unsigned int type){
  SBAwayMediaControlsView *view = [[[[objc_getClass("SBAwayController") sharedAwayController] awayView] dateView] controlsView];
  UIPushButton *_nextButton = MSHookIvar<UIPushButton *>(view, "_nextButton");

  if(type == increaseButtonID[0])
    [view _changeTrackButtonDown:_nextButton];

  if(type == increaseButtonID[1])
    [view _changeTrackButtonUp:_nextButton];
}

static void hookDecreaseVolume(unsigned int type){
  SBAwayMediaControlsView *view = [[[[objc_getClass("SBAwayController") sharedAwayController] awayView] dateView] controlsView];
  UIPushButton *_prevButton = MSHookIvar<UIPushButton *>(view, "_prevButton");

  if(type == decreaseButtonID[0])
    [view _changeTrackButtonDown:_prevButton];

  if(type == decreaseButtonID[1])
    [view _changeTrackButtonUp:_prevButton];
}

static void (*_SpringBoard$lockButtonDown$)(id self, SEL cmd_, GSEventRef down) = NULL;
static void $SpringBoard$lockButtonDown$(id self, SEL cmd_, GSEventRef down){
  startInvocationGloveTimer();
  _SpringBoard$lockButtonDown$(self, cmd_, down);
}

static void (*_SpringBoard$lockButtonUp$)(id self, SEL cmd_, GSEventRef up) = NULL;
static void $SpringBoard$lockButtonUp$(id self, SEL cmd_, GSEventRef up){
  cancelInvocationGloveTimer();
  _SpringBoard$lockButtonUp$(self, cmd_, up);
}

static void (*_SBMediaController$increaseVolume$)(id self, SEL cmd_) = NULL;
static void $SBMediaController$increaseVolume$(id self, SEL cmd_){
  if(!isShowing())
    _SBMediaController$increaseVolume$(self, cmd_);
}

static void (*_SBMediaController$decreaseVolume$)(id self, SEL cmd_) = NULL;
static void $SBMediaController$decreaseVolume$(id self, SEL cmd_){
  if(!isShowing())
    _SBMediaController$decreaseVolume$(self, cmd_);
}

static void (*_SBMediaController$handleVolumeEvent$)(id self, SEL cmd_, GSEventRef event) = NULL;
static void $SBMediaController$handleVolumeEvent$(id self, SEL cmd_, GSEventRef event){
  uint32_t type = GSEventGetType(event);

  if(isShowing()){
    if(type == increaseButtonID[0] || type == increaseButtonID[1])
      hookIncreaseVolume(type);

    if(type == decreaseButtonID[0] || type == decreaseButtonID[1])
      hookDecreaseVolume(type);
  }

  _SBMediaController$handleVolumeEvent$(self, cmd_, event);
}

__attribute__((constructor)) static void initialize(){
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
  if (![identifier isEqualToString:@"com.apple.springboard"])
    return;

  Class $SpringBoard(objc_getClass("SpringBoard"));
  class_addMethod($SpringBoard, @selector(invokeGlovePod), (IMP)&$SpringBoard$invokeGlovePod, "v@:");
  _SpringBoard$lockButtonUp$ = MSHookMessage($SpringBoard, @selector(lockButtonUp:), &$SpringBoard$lockButtonUp$);
  _SpringBoard$lockButtonDown$ = MSHookMessage($SpringBoard, @selector(lockButtonDown:), &$SpringBoard$lockButtonDown$);

  Class $SBMediaController(objc_getClass("SBMediaController"));
  _SBMediaController$increaseVolume$ = MSHookMessage($SBMediaController, @selector(increaseVolume), &$SBMediaController$increaseVolume$);
  _SBMediaController$decreaseVolume$ = MSHookMessage($SBMediaController, @selector(decreaseVolume), &$SBMediaController$decreaseVolume$);
  _SBMediaController$handleVolumeEvent$ = MSHookMessage($SBMediaController, @selector(handleVolumeEvent:), &$SBMediaController$handleVolumeEvent$);

  [pool release];
}
