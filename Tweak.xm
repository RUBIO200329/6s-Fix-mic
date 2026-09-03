#import <ellekit.h>  // o <substrate.h> según qué headers tengas para MSHookFunction

static OSStatus (*orig_AudioOutputUnitStart)(void *ci);
static OSStatus hook_AudioOutputUnitStart(void *ci) {
    fileLog(@"AudioOutputUnitStart interceptado");
    forceMic(@"AudioOutputUnitStart");
    return orig_AudioOutputUnitStart(ci);
}

%ctor {
    fileLog(@"MicDefault cargado en proceso");
    void *audioToolbox = dlopen("/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox", RTLD_LAZY);
    void *sym = dlsym(audioToolbox, "AudioOutputUnitStart");
    if (sym) {
        MSHookFunction(sym, (void *)hook_AudioOutputUnitStart, (void **)&orig_AudioOutputUnitStart);
        fileLog(@"Hook de AudioOutputUnitStart instalado");
    } else {
        fileLog(@"No se encontro el simbolo AudioOutputUnitStart");
    }
}
