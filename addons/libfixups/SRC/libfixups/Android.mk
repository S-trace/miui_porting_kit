LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := fts.c
LOCAL_SRC_FILES += reservedVectorImpl.c
LOCAL_SRC_FILES += vibrator.c
LOCAL_MODULE := libfixups
include $(BUILD_SHARED_LIBRARY)
