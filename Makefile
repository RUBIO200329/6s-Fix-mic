ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MicDefault
MicDefault_FILES = Tweak.xm
MicDefault_FRAMEWORKS = AVFoundation Foundation

TOOL_NAME = micdefault
micdefault_FILES = micdefault.m
micdefault_CFLAGS = -fobjc-arc
micdefault_FRAMEWORKS = Foundation AVFoundation

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/tool.mk

after-install::
	install.exec "killall -9 SpringBoard"
