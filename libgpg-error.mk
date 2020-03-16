ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

ifneq ($(wildcard $(BUILD_WORK)/libgpg-error/.build_complete),)
libgpg-error:
	@echo "Using previously built libgpg-error."
else
libgpg-error: setup
	# This hack makes me extremely sad. System-cmds won't build without these libkern headers, but they interfere with iOS headers in this case.
	mv $(BUILD_BASE)/usr/include/libkern $(BUILD_BASE)/usr/include/libkern.bak
	$(SED) -i '/{"armv7-unknown-linux-gnueabihf"  },/a \ \ \ \ {"$(GNU_HOST_TRIPLE)"},' $(BUILD_WORK)/libgpg-error/src/mkheader.c
	cd $(BUILD_WORK)/libgpg-error && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	$(MAKE) -C $(BUILD_WORK)/libgpg-error
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/libgpg-error install \
		DESTDIR=$(BUILD_STAGE)/libgpg-error
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/libgpg-error install \
		DESTDIR=$(BUILD_BASE)
	mv $(BUILD_BASE)/usr/include/libkern.bak $(BUILD_BASE)/usr/include/libkern	
	touch $(BUILD_WORK)/libgpg-error/.build_complete
endif

.PHONY: libgpg-error
