#import <AVFoundation/AVFoundation.h>

#define PLIST_PATH @"/var/mobile/Library/Preferences/com.tuusuario.micdefault.plist"
#define LOG_PATH @"/var/mobile/miclog.txt"

static void fileLog(NSString *msg) {
    NSString *line = [NSString stringWithFormat:@"%@ %@\n", [NSDate date], msg];
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:LOG_PATH];
    if (!fh) {
        [[NSFileManager defaultManager] createFileAtPath:LOG_PATH contents:nil attributes:nil];
        fh = [NSFileHandle fileHandleForWritingAtPath:LOG_PATH];
    }
    [fh seekToEndOfFile];
    [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];
}

static NSString *preferredOrientation() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH];
    NSString *val = prefs[@"MicSource"];
    return val ?: @"Bottom";
}

static AVAudioSessionPortDescription *portWithWantedSource(AVAudioSession *session, NSString *wanted) {
    for (AVAudioSessionPortDescription *port in session.availableInputs) {
        if ([port.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
            for (AVAudioSessionDataSourceDescription *src in port.dataSources) {
                if ([src.orientation isEqualToString:wanted]) {
                    NSError *err = nil;
                    [port setPreferredDataSource:src error:&err];
                    fileLog([NSString stringWithFormat:@"dataSource -> %@ (err: %@)", wanted, err]);
                    return port;
                }
            }
        }
    }
    return nil;
}

static void forceMic(NSString *origin) {
    NSString *wanted = preferredOrientation();
    AVAudioSessionPortDescription *port = portWithWantedSource([AVAudioSession sharedInstance], wanted);
    if (port) {
        NSError *err = nil;
        [[AVAudioSession sharedInstance] setPreferredInput:port error:&err];
        fileLog([NSString stringWithFormat:@"%@ -> preferredInput forzado (err: %@)", origin, err]);
    }
}

%hook AVAudioSession

- (BOOL)setActive:(BOOL)active error:(NSError **)outError {
    BOOL result = %orig;
    fileLog(@"setActive disparado");
    if (active) forceMic(@"setActive");
    return result;
}

- (BOOL)setActive:(BOOL)active withOptions:(AVAudioSessionSetActiveOptions)options error:(NSError **)outError {
    BOOL result = %orig;
    fileLog(@"setActive:withOptions: disparado");
    if (active) forceMic(@"setActive:withOptions:");
    return result;
}

- (BOOL)setPreferredInput:(AVAudioSessionPortDescription *)inPort error:(NSError **)outError {
    fileLog(@"setPreferredInput interceptado");
    if ([inPort.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
        NSString *wanted = preferredOrientation();
        portWithWantedSource(self, wanted);
    }
    return %orig(inPort, outError);
}

%end

%hook AVAudioRecorder

- (BOOL)prepareToRecord {
    fileLog(@"AVAudioRecorder prepareToRecord");
    forceMic(@"prepareToRecord");
    return %orig;
}

- (BOOL)record {
    fileLog(@"AVAudioRecorder record");
    forceMic(@"record");
    return %orig;
}

%end

%ctor {
    fileLog(@"MicDefault cargado en proceso");
}

