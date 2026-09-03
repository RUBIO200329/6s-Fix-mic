THEOS_PACKAGE_SCHEME = rootless

ARCHS = arm64
TARGET=iphone:clang:latest:15.0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MicSelect

MicSelect_FILES = Tweak.xm
MicSelect_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
