#import <AVFoundation/AVFoundation.h>

#define PLIST_PATH @"/var/mobile/Library/Preferences/com.tuusuario.micdefault.plist"

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
                    NSLog(@"[MicDefault] dataSource -> %@ (err: %@)", wanted, err);
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
        NSString *wanted = preferredOrientation();
        AVAudioSessionPortDescription *port = portWithWantedSource(self, wanted);
        if (port) {
            NSError *err = nil;
            [self setPreferredInput:port error:&err];
            NSLog(@"[MicDefault] setActive -> preferredInput forzado (err: %@)", err);
        }
    }
    return result;
}

- (BOOL)setPreferredInput:(AVAudioSessionPortDescription *)inPort error:(NSError **)outError {
    NSString *wanted = preferredOrientation();
    if ([inPort.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
        portWithWantedSource(self, wanted);
    }
    NSLog(@"[MicDefault] setPreferredInput interceptado, forzando %@", wanted);
    return %orig(inPort, outError);
}

%end
