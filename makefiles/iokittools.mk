ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS        += iokittools
ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 1800 ] && echo 1),1)
IOKITTOOLS_VERSION := 124
else
IOKITTOOLS_VERSION := 115
endif
DEB_IOKITTOOLS_V   ?= $(IOKITTOOLS_VERSION)

iokittools-setup: setup
	$(call GITHUB_ARCHIVE,apple-oss-distributions,IOKitTools,$(IOKITTOOLS_VERSION),IOKitTools-$(IOKITTOOLS_VERSION))
	$(call EXTRACT_TAR,IOKitTools-$(IOKITTOOLS_VERSION).tar.gz,IOKitTools-IOKitTools-$(IOKITTOOLS_VERSION),iokittools)
	sed -i -e 's|#include <Kernel/IOKit/IOKitDebug.h>|#include <IOKit/IOKitDebug.h>|g' \
		-e 's|#include <Kernel/libkern/OSKextLibPrivate.h>|#include <libkern/OSKextLibPrivate.h>|g' \
		$(BUILD_WORK)/iokittools/ioclasscount.tproj/ioclasscount.c
	mkdir -p $(BUILD_STAGE)/iokittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man8}

ifneq ($(wildcard $(BUILD_WORK)/iokittools/.build_complete),)
iokittools:
	@echo "Using previously built iokittools."
else
iokittools: iokittools-setup
	cd $(BUILD_WORK)/iokittools; \
	for bin in ioalloccount ioclasscount; do \
		case $$bin in \
			ioclasscount) LDFLAGS_extra="-F$(BUILD_MISC)/PrivateFrameworks -framework CoreSymbolication -framework perfdata"; \
		esac; \
		$(CC) $${LDFLAGS_extra} $(LDFLAGS) $(CFLAGS) -framework CoreFoundation -framework IOKit -o $(BUILD_STAGE)/iokittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$bin $$bin.tproj/*.c; \
		$(INSTALL) -m644 $(BUILD_WORK)/iokittools/$$bin.tproj/$$bin.8 $(BUILD_STAGE)/iokittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/$$bin.8 ;\
	done; \
	$(INSTALL) -m644 $(BUILD_WORK)/iokittools/ioreg.tproj/ioreg.8 $(BUILD_STAGE)/iokittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/ioreg.8
	$(call AFTER_BUILD)
endif

iokittools-package: iokittools-stage
	# iokittools.mk Package Structure
	rm -rf $(BUILD_DIST)/iokittools

	# iokittools.mk Prep iokittools
	cp -a $(BUILD_STAGE)/iokittools $(BUILD_DIST)

	# iokittools.mk Sign
	$(call SIGN,iokittools,general.xml)
	$(LDID) -M -S$(BUILD_MISC)/entitlements/ioclasscount.plist $(BUILD_DIST)/iokittools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ioclasscount

	# iokittools.mk Make .debs
	$(call PACK,iokittools,DEB_IOKITTOOLS_V)

	# iokittools.mk Build cleanup
	rm -rf $(BUILD_DIST)/iokittools

.PHONY: iokittools iokittools-package
endif
