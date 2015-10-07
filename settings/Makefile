include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = NotificationProfiles
NotificationProfiles_FILES = NotificationProfiles.mm
NotificationProfiles_INSTALL_PATH = /Library/PreferenceBundles
NotificationProfiles_FRAMEWORKS = UIKit
NotificationProfiles_PRIVATE_FRAMEWORKS = Preferences
ADDITIONAL_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/NotificationProfiles.plist$(ECHO_END)
