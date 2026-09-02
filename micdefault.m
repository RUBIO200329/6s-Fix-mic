#import <sys/stat.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define PLIST_PATH @"/var/mobile/Library/Preferences/com.tuusuario.micdefault.plist"

static void printUsage() {
    printf("Uso:\n");
    printf("  micdefault set <bottom|front|back>\n");
    printf("  micdefault get\n");
    printf("  micdefault list   (muestra los mics disponibles en este dispositivo)\n");
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        if (argc < 2) { printUsage(); return 1; }
        NSString *cmd = [NSString stringWithUTF8String:argv[1]];

        if ([cmd isEqualToString:@"set"]) {
            if (argc < 3) { printUsage(); return 1; }
            NSString *val = [[NSString stringWithUTF8String:argv[2]] capitalizedString];
            if (![@[@"Bottom", @"Front", @"Back"] containsObject:val]) {
                printf("Valor invalido. Usa: bottom | front | back\n");
                return 1;
            }
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:PLIST_PATH] ?: [NSMutableDictionary new];
            dict[@"MicSource"] = val;
            BOOL ok = [dict writeToFile:PLIST_PATH atomically:YES];
            chmod([PLIST_PATH UTF8String], 0644);
            printf(ok ? "OK, mic por defecto -> %s\n" : "Fallo al escribir plist\n", val.UTF8String);
            return ok ? 0 : 1;

        } else if ([cmd isEqualToString:@"get"]) {
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH];
            NSString *val = dict[@"MicSource"] ?: @"Bottom (default)";
            printf("Mic actual configurado: %s\n", val.UTF8String);
            return 0;

        } else if ([cmd isEqualToString:@"list"]) {
            AVAudioSession *session = [AVAudioSession sharedInstance];
            NSError *err = nil;
            [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
            [session setActive:YES error:&err];
            for (AVAudioSessionPortDescription *port in session.availableInputs) {
                if ([port.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
                    for (AVAudioSessionDataSourceDescription *src in port.dataSources) {
                        printf("- %s (activo: %s)\n", src.orientation.UTF8String,
                               [src isEqual:port.selectedDataSource] ? "si" : "no");
                    }
                }
            }
            return 0;

        } else {
            printUsage();
            return 1;
        }
    }
}
