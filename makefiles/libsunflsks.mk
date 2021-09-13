ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libsunflsks
LIBSUNFLSKS_VERSION := 1.0.2
LIBSUNFLSKS_COMMIT  := d0bb5bbaf9f0ac6e5e3ea61c21b3bbb637f2061d
LIBSUNFLSKS_SOVER   := 0
DEB_LIBSUNFLSKS_V   ?= $(LIBSUNFLSKS_VERSION)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
LIBSUNFLSKS_HEADERS := \#import <UIKit/UIKit.h>
LIBSUNFLSKS_CFLAGS  := src/Network.m src/SystemStatus.m
LIBSUNFLSKS_OBJECTS := Network.o SystemStatus.o
LIBSUNFLSKS_LDFLAGS := $(LIBSUNFLSKS_OBJECTS) -framework CoreTelephony -framework UIKit
LIBSUNFLSKS_ARFLAGS := $(LIBSUNFLSKS_OBJECTS)
endif

libsunflsks-setup: setup
	$(call GITHUB_ARCHIVE,sunflsks,libsunflsks,$(LIBSUNFLSKS_COMMIT),$(LIBSUNFLSKS_COMMIT))
	$(call EXTRACT_TAR,libsunflsks-$(LIBSUNFLSKS_COMMIT).tar.gz,libsunflsks-$(LIBSUNFLSKS_COMMIT),libsunflsks)
	sed -i '1 i\#import <Foundation/Foundation.h>\n$(LIBSUNFLSKS_HEADERS)' $(BUILD_WORK)/libsunflsks/src/*.m
	mkdir -p $(BUILD_STAGE)/libsunflsks/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include/sunflsks,share/doc/libsunflsks}

ifneq ($(wildcard $(BUILD_WORK)/libsunflsks/.build_complete),)
libsunflsks:
	@echo "Using previously built libsunflsks."
else
libsunflsks: libsunflsks-setup
	cd $(BUILD_WORK)/libsunflsks && \
		$(CC) $(CFLAGS) -Ilib lib/*.m src/{ProcessInfo,FileInfo,ProcessManager,Translate}.m $(LIBSUNFLSKS_CFLAGS) -fobjc-arc -c; \
		$(CC) $(LDFLAGS) -shared ./{ProcessInfo,FileInfo,ProcessManager,Translate,Reachability}.o $(LIBSUNFLSKS_LDFLAGS) -framework CoreFoundation -framework Foundation -framework SystemConfiguration -o $(BUILD_STAGE)/libsunflsks/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsunflsks.0.dylib; \
		$(AR) cru $(BUILD_STAGE)/libsunflsks/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsunflsks.a ./{ProcessInfo,FileInfo,ProcessManager,Translate}.o $(LIBSUNFLSKS_ARFLAGS); \
		cp -a include/* $(BUILD_STAGE)/libsunflsks/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sunflsks
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
		rm -f $(BUILD_STAGE)/libsunflsks/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/Network.h
endif
		$(LN_S) $(BUILD_STAGE)/libsunflsks/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsunflsks.{0.,}dylib
	$(call AFTER_BUILD,copy)
endif

libsunflsks-package: libsunflsks-stage
	# libsunflsks.mk Package Structure
	rm -rf $(BUILD_DIST)/libsunflsks{0,-dev}
	mkdir -p $(BUILD_DIST)/libsunflsks{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libsunflsks.mk Prep libsunflsks0
	cp -a $(BUILD_STAGE)/libsunflsks/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsunflsks.0.dylib $(BUILD_DIST)/libsunflsks0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libsunflsks.mk Prep libsunflsks-dev
	cp -a $(BUILD_STAGE)/libsunflsks/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsunflsks-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libsunflsks/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsunflsks.{dylib,a} $(BUILD_DIST)/libsunflsks-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libsunflsks.mk Sign
	$(call SIGN,libsunflsks0,general.xml)
	
	# libsunflsks.mk Make .debs
	$(call PACK,libsunflsks0,DEB_LIBSUNFLSKS_V)
	$(call PACK,libsunflsks-dev,DEB_LIBSUNFLSKS_V)
	
	# libsunflsks.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsunflsks{0,-dev}

.PHONY: libsunflsks libsunflsks-package
