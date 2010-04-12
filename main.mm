extern void initPreferences();
extern void initGlovePod();

__attribute__((constructor)) static void initialize()
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    if (![identifier isEqualToString:@"com.apple.springboard"])
        return;

    initPreferences();
    initGlovePod();

    [pool release];
}
