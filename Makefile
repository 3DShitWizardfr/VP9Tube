export THEOS ?= $(THEOS_PATH)

# Uncomment and set these for over-the-air installation:
# THEOS_DEVICE_IP = 
# THEOS_DEVICE_PORT = 

INSTALL_TARGET_PROCESSES = YouTube
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VP9Tube
$(TWEAK_NAME)_FILES = src/Tweak.x src/VP9SoftwareDecoder.mm
$(TWEAK_NAME)_FRAMEWORKS = CoreMedia CoreVideo VideoToolbox Foundation
$(TWEAK_NAME)_CFLAGS = -Ilibvpx-ios/include
$(TWEAK_NAME)_LDFLAGS = -Llibvpx-ios/lib -lvpx

include $(THEOS_MAKE_PATH)/tweak.mk
