LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)
LOCAL_SRC_FILES:= reservedVectorImpl.c
LOCAL_MODULE := libreservedVectorImpl
include $(BUILD_SHARED_LIBRARY)
