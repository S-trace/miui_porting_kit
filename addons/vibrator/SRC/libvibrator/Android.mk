LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)
LOCAL_SRC_FILES:= vibrator.c
LOCAL_MODULE := libvibrator
include $(BUILD_SHARED_LIBRARY)
