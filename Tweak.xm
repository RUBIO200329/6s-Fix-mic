#import <Foundation/Foundation.h>
#import <AVFAudio/AVFAudio.h>

static NSString *const kPrefsPath =
    @"/var/jb/var/mobile/Library/Preferences/com.micselect.preferences.plist";

static NSInteger MicSelectMode(void) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefsPath];
    NSNumber *value = prefs[@"SelectedMic"];
    return value ? value.integerValue : 0;
}

static void LogAvailableMicrophones(AVAudioSession *session) {
    AVAudioSessionRouteDescription *route = session.currentRoute;

    for (AVAudioSessionPortDescription *port in route.inputs) {
        NSLog(@"[MicSelect] INPUT PORT: %@", port.portName);
        NSLog(@"[MicSelect] TYPE: %@", port.portType);

        NSArray *sources = port.dataSources;
        if (!sources) {
            NSLog(@"[MicSelect] No selectable data sources");
            continue;
        }

        for (AVAudioSessionDataSourceDescription *source in sources) {
            NSLog(@"[MicSelect] DATA SOURCE:");
            NSLog(@"[MicSelect]   name = %@", source.dataSourceName);
            NSLog(@"[MicSelect]   ID = %@", source.dataSourceID);
            NSLog(@"[MicSelect]   location = %@", source.location);
            NSLog(@"[MicSelect]   orientation = %@", source.orientation);
        }

        NSLog(@"[MicSelect] SELECTED = %@",
              port.selectedDataSource.dataSourceName);
    }
}

static void ApplyMicrophoneSelection(void) {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSInteger selection = MicSelectMode();

    NSLog(@"[MicSelect] Requested microphone: %ld", (long)selection);
    LogAvailableMicrophones(session);

    // v0.1 is diagnostic only: do not change the microphone yet.
    if (selection != 0)
        NSLog(@"[MicSelect] Selection requested, but v0.1 is diagnostic-only.");
}

%hook AVAudioSession

- (BOOL)setActive:(BOOL)active error:(NSError **)error {
    BOOL result = %orig;

    if (active) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                      (int64_t)(0.15 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            ApplyMicrophoneSelection();
        });
    }
    return result;
}

- (BOOL)setActive:(BOOL)active
      withOptions:(AVAudioSessionSetActiveOptions)options
            error:(NSError **)error {
    BOOL result = %orig;

    if (active) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                      (int64_t)(0.15 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            ApplyMicrophoneSelection();
        });
    }
    return result;
}

%end

%ctor {
    NSLog(@"[MicSelect] Loaded - iOS 15 diagnostic build");
}
