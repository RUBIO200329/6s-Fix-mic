#import <AVFoundation/AVFoundation.h>

#define PLIST_PATH @"/var/mobile/Library/Preferences/com.tuusuario.micdefault.plist"

static NSString *preferredOrientation() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH];
    NSString *val = prefs[@"MicSource"];
    return val ?: @"Bottom"; // Bottom / Front / Back
}

%hook AVAudioSession

- (BOOL)setActive:(BOOL)active error:(NSError **)outError {
    BOOL result = %orig;
    if (active) {
        NSString *wanted = preferredOrientation();
        for (AVAudioSessionPortDescription *port in self.availableInputs) {
            if ([port.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
                for (AVAudioSessionDataSourceDescription *src in port.dataSources) {
                    if ([src.orientation isEqualToString:wanted]) {
                        NSError *err = nil;
                        [port setPreferredDataSource:src error:&err];
                        [self setPreferredInput:port error:&err];
                        break;
                    }
                }
            }
        }
    }
    return result;
}

%end

%ctor {
    // se carga en cualquier proceso que enlace UIKit (ver filtro en control/Info.plist de Substrate)
}
