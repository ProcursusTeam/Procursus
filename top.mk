ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += top
DOWNLOAD      += https://opensource.apple.com/tarballs/top/top-$(TOP_VERSION).tar.gz
TOP_VERSION   := 125
DEB_TOP_V     ?= $(TOP_VERSION)

top-setup: setup
	$(call EXTRACT_TAR,top-$(TOP_VERSION).tar.gz,top-$(TOP_VERSION),top)
	mkdir -p $(BUILD_WORK)/top/include/{IOKit/storage,mach}
	cp -a $(MACOSX_SYSROOT)/usr/include/libkern $(BUILD_WORK)/top/include
	cp -a $(MACOSX_SYSROOT)/usr/include/mach/mach_vm.h $(BUILD_WORK)/top/include/mach
	cp -a $(MACOSX_SYSROOT)/usr/include/nlist.h $(BUILD_WORK)/top/include
	cp -a $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* $(BUILD_WORK)/top/include/IOKit
	wget -nc -P $(BUILD_WORK)/top/include \
		https://opensource.apple.com/source/libutil/libutil-57/libutil.h
	wget -nc -P $(BUILD_WORK)/top/include/mach \
		https://opensource.apple.com/source/xnu/xnu-6153.11.26/osfmk/mach/shared_region.h
	wget -nc -P $(BUILD_WORK)/top \
		https://opensource.apple.com/source/libutil/libutil-57/humanize_number.c
	$(SED) -i 's/ARM:/ARM64:/g' $(BUILD_WORK)/top/libtop.c
	$(SED) -i 's/ARM;/ARM64;/g' $(BUILD_WORK)/top/libtop.c

ifneq ($(wildcard $(BUILD_WORK)/top/.build_complete),)
top:
	@echo "Using previously built top."
else
top: top-setup ncurses
	mkdir -p $(BUILD_STAGE)/top/usr/bin/
	$(CC) $(CFLAGS) -isystem $(BUILD_WORK)/top/include -L $(BUILD_BASE)/usr/lib -o $(BUILD_STAGE)/top/usr/bin/top $(BUILD_WORK)/top/*.c -framework IOKit -framework CoreFoundation -lncursesw -lpanelw;
	touch $(BUILD_WORK)/top/.build_complete
endif

top-package: top-stage
	# top.mk Package Structure
	rm -rf $(BUILD_DIST)/top
	
	# top.mk Prep top
	$(FAKEROOT) cp -a $(BUILD_STAGE)/top/usr $(BUILD_DIST)/top
	
	# top.mk Sign
	$(call SIGN,top,top.xml)
	
	# top.mk Make .debs
	$(call PACK,top,DEB_TOP_V)
	
	# top.mk Build cleanup
	rm -rf $(BUILD_DIST)/top

.PHONY: top top-package
