export GO_EASY_ON_ME=1
TARGET := appletv:clang:latest:9.0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = APFSUtil

APFSUtil_FILES = main.m APFSHelper.m
APFSUtil_CFLAGS = -fobjc-arc -Iinclude
APFSUtil_CODESIGN_FLAGS = -Sentitlements.plist
APFSUtil_INSTALL_PATH = /fs/jb/usr/local/bin
APFSUtil_LDFLAGS = -framework APFS -framework IOKit -L. -FFrameworks
APFSUtil_CODESIGN_FLAGS=-Sapfs.xml

include $(THEOS_MAKE_PATH)/tool.mk
