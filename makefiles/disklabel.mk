ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += disklabel
DISKLABEL_VERSION := 7
DEB_DISKLABEL_V   ?= $(DISKLABEL_VERSION)

disklabel-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://opensource.apple.com/tarballs/disklabel/disklabel-$(DISKLABEL_VERSION).tar.gz)
	$(call EXTRACT_TAR,disklabel-$(DISKLABEL_VERSION).tar.gz,disklabel-$(DISKLABEL_VERSION),disklabel)
	sed -i 's|#include <Kernel/libkern/OSByteOrder.h>|#include <libkern/OSByteOrder.h>|g' $(BUILD_WORK)/disklabel/util.c
	mkdir -p $(BUILD_STAGE)/disklabel/$(MEMO_PREFIX)/{sbin,$(MEMO_SUB_PREFIX)/share/man/man8}

ifneq ($(wildcard $(BUILD_WORK)/disklabel/.build_complete),)
disklabel:
	@echo "Using previously built disklabel."
else
disklabel: disklabel-setup
	cd $(BUILD_WORK)/disklabel; \
	$(CC) $(CFLAGS) $(LDFLAGS) {create,destroy,main,props,status,util}.c -lutil -lz -framework CoreFoundation -o $(BUILD_STAGE)/disklabel/$(MEMO_PREFIX)/sbin/disklabel -D__kernel_ptr_semantics=""; \
	$(INSTALL) -m644 disklabel.8 $(BUILD_STAGE)/disklabel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8
	$(call AFTER_BUILD)
endif

disklabel-package: disklabel-stage
	# disklabel.mk Package Structure
	rm -rf $(BUILD_DIST)/disklabel
	
	# disklabel.mk Prep disklabel
	cp -a $(BUILD_STAGE)/disklabel $(BUILD_DIST)
	
	# disklabel.mk Sign
	$(call SIGN,disklabel,dd.xml)
	
	# disklabel.mk Make .debs
	$(call PACK,disklabel,DEB_DISKLABEL_V)
	
	# disklabel.mk Build cleanup
	rm -rf $(BUILD_DIST)/disklabel

.PHONY: disklabel disklabel-package
