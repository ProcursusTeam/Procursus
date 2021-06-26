ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += iokittools
IOKITTOOLS_VERSION := 91
DEB_IOKITTOOLS_V   ?= $(IOKITTOOLS_VERSION)

iokittools-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/IOKitTools/IOKitTools-$(IOKITTOOLS_VERSION).tar.gz
	$(call EXTRACT_TAR,IOKitTools-$(IOKITTOOLS_VERSION).tar.gz,IOKitTools-$(IOKITTOOLS_VERSION),iokittools)
	mkdir -p $(BUILD_STAGE)/iokittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin

	# Mess of copying over headers because some build_base headers interfere with the build of Apple cmds.
	mkdir -p $(BUILD_WORK)/iokittools/include/IOKit
	cp -a $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* $(BUILD_WORK)/iokittools/include/IOKit
	cp -a $(MACOSX_SYSROOT)/usr/include/libkern $(BUILD_WORK)/iokittools/include

	wget -q -nc -P $(BUILD_WORK)/iokittools/include/IOKit \
		https://opensource.apple.com/source/IOKitUser/IOKitUser-1726.11.1/IOKitLibPrivate.h

ifneq ($(wildcard $(BUILD_WORK)/iokittools/.build_complete),)
iokittools:
	@echo "Using previously built iokittools."
else
iokittools: iokittools-setup ncurses
	cd $(BUILD_WORK)/iokittools; \
	for tproj in {ioalloccount,ioclasscount}.tproj; do \
		tproj=$$(basename $$tproj .tproj); \
		$(CC) $(CFLAGS) -L $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -isystem include -o $(BUILD_STAGE)/iokittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/$$tproj $$tproj.tproj/*.c -framework CoreFoundation -framework IOKit -lncursesw; \
	done
	touch $(BUILD_WORK)/iokittools/.build_complete
endif

iokittools-package: iokittools-stage
	# iokittools.mk Package Structure
	rm -rf $(BUILD_DIST)/iokittools

	# iokittools.mk Prep iokittools
	cp -a $(BUILD_STAGE)/iokittools $(BUILD_DIST)

	# iokittools.mk Sign
	$(call SIGN,iokittools,general.xml)

	# iokittools.mk Make .debs
	$(call PACK,iokittools,DEB_IOKITTOOLS_V)

	# iokittools.mk Build cleanup
	rm -rf $(BUILD_DIST)/iokittools

.PHONY: iokittools iokittools-package
