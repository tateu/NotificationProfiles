export GO_EASY_ON_ME = 1

export ARCHS = armv7 arm64
export SDKVERSION = 7.0
export TARGET = iphone:clang:latest:7.0

PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NotificationProfiles
NotificationProfiles_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += settings
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
