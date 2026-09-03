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

%hook AVAudioSession

- (BOOL)setActive:(BOOL)active error:(NSError **)outError {
    BOOL result = %orig;
    if (active) {
        fileLog(@"setActive disparado");
        NSString *wanted = preferredOrientation();
        AVAudioSessionPortDescription *port = portWithWantedSource(self, wanted);
        if (port) {
            NSError *err = nil;
            [self setPreferredInput:port error:&err];
            fileLog([NSString stringWithFormat:@"preferredInput forzado (err: %@)", err]);
        }
    }
    return result;
}

- (BOOL)setPreferredInput:(AVAudioSessionPortDescription *)inPort error:(NSError **)outError {
    fileLog(@"setPreferredInput interceptado");
    NSString *wanted = preferredOrientation();
    if ([inPort.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
        portWithWantedSource(self, wanted);
    }
    return %orig(inPort, outError);
}

%end

%ctor {
    fileLog(@"MicDefault cargado en proceso");
}

%hook AVAudioRecorder

- (BOOL)prepareToRecord {
    fileLog(@"AVAudioRecorder prepareToRecord");
    NSString *wanted = preferredOrientation();
    portWithWantedSource([AVAudioSession sharedInstance], wanted);
    [[AVAudioSession sharedInstance] setPreferredInput:portWithWantedSource([AVAudioSession sharedInstance], wanted) error:nil];
    return %orig;
}

- (BOOL)record {
    fileLog(@"AVAudioRecorder record");
    NSString *wanted = preferredOrientation();
    AVAudioSessionPortDescription *port = portWithWantedSource([AVAudioSession sharedInstance], wanted);
    if (port) {
        NSError *err = nil;
        [[AVAudioSession sharedInstance] setPreferredInput:port error:&err];
        fileLog([NSString stringWithFormat:@"record -> preferredInput forzado (err: %@)", err]);
    }
    return %orig;
}

%end

