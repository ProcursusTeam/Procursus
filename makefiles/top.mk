ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS   += top
TOP_VERSION   := 125
DEB_TOP_V     ?= $(TOP_VERSION)

top-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,top,$(TOP_VERSION),top-$(TOP_VERSION))
	$(call EXTRACT_TAR,top-$(TOP_VERSION).tar.gz,top-top-$(TOP_VERSION),top)
	mkdir -p $(BUILD_WORK)/top/include/{IOKit/storage,mach}
	cp -a $(MACOSX_SYSROOT)/usr/include/libkern $(BUILD_WORK)/top/include
	cp -a $(MACOSX_SYSROOT)/usr/include/mach/mach_vm.h $(BUILD_WORK)/top/include/mach
	cp -a $(MACOSX_SYSROOT)/usr/include/nlist.h $(BUILD_WORK)/top/include
	cp -a $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* $(BUILD_WORK)/top/include/IOKit
	$(call DOWNLOAD_FILES,$(BUILD_WORK)/top/include, \
		https://github.com/apple-oss-distributions/libutil/raw/libutil-57/libutil.h)
	$(call DOWNLOAD_FILES,$(BUILD_WORK)/top/include/mach, \
		https://github.com/apple-oss-distributions/xnu/raw/xnu-8792.81.2/osfmk/mach/shared_region.h)
	sed -i 's/ARM:/ARM64:/g' $(BUILD_WORK)/top/libtop.c
	sed -i 's/ARM;/ARM64;/g' $(BUILD_WORK)/top/libtop.c

ifneq ($(wildcard $(BUILD_WORK)/top/.build_complete),)
top:
	@echo "Using previously built top."
else
top: top-setup ncurses
	mkdir -p $(BUILD_STAGE)/top/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	$(CC) $(CFLAGS) -liosexec -isystem $(BUILD_WORK)/top/include -L $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -o $(BUILD_STAGE)/top/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/top $(BUILD_WORK)/top/*.c -framework IOKit -framework CoreFoundation -lncursesw -lpanelw -lutil;
	$(call AFTER_BUILD)
endif

top-package: top-stage
	# top.mk Package Structure
	rm -rf $(BUILD_DIST)/top
	mkdir -p $(BUILD_DIST)/top

	# top.mk Prep top
	cp -a $(BUILD_STAGE)/top $(BUILD_DIST)

	# top.mk Sign
	$(call SIGN,top,top.xml)

	# top.mk Permissions
	chmod u+s $(BUILD_DIST)/top/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/top

	# top.mk Make .debs
	$(call PACK,top,DEB_TOP_V)

	# top.mk Build cleanup
	rm -rf $(BUILD_DIST)/top

.PHONY: top top-package

endif
