LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)
LOCAL_SRC_FILES:= fts.c
LOCAL_MODULE := libfts
include $(BUILD_SHARED_LIBRARY)
