ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libsigsegv
LIBSIGSEGV_VERSION := 2.13
DEB_LIBSIGSEGV_V   ?= $(LIBSIGSEGV_VERSION)

libsigsegv-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://ftp.gnu.org/gnu/libsigsegv/libsigsegv-$(LIBSIGSEGV_VERSION).tar.gz
	$(call EXTRACT_TAR,libsigsegv-$(LIBSIGSEGV_VERSION).tar.gz,libsigsegv-$(LIBSIGSEGV_VERSION),libsigsegv)
	$(SED) -i 's|#include <nlist.h>|#include <mach-o/nlist.h>|g' $(BUILD_WORK)/libsigsegv/src/stackvma-mach.c

ifneq ($(wildcard $(BUILD_WORK)/libsigsegv/.build_complete),)
libsigsegv:
	@echo "Using previously built libsigsegv."
else
libsigsegv: libsigsegv-setup
	cd $(BUILD_WORK)/libsigsegv && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-static \
		--enable-shared
	+$(MAKE) -C $(BUILD_WORK)/libsigsegv
	+$(MAKE) -C $(BUILD_WORK)/libsigsegv install \
		DESTDIR=$(BUILD_STAGE)/libsigsegv
	+$(MAKE) -C $(BUILD_WORK)/libsigsegv install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libsigsegv/.build_complete
endif

libsigsegv-package: libsigsegv-stage
	# libsigsegv.mk Package Structure
	rm -rf $(BUILD_DIST)/libsigsegv{2,-dev}
	mkdir -p $(BUILD_DIST)/libsigsegv{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libsigsegv.mk Prep libsigsegv2
	cp -a $(BUILD_STAGE)/libsigsegv/$(MEMO_PREIFX)$(MEMO_SUB_PREFIX)/lib/libsigsegv.2.dylib $(BUILD_DIST)/libsigsegv2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libsigsegv.mk Prep libsigsegv-dev
	cp -a $(BUILD_STAGE)/libsigsegv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsigsegv-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libsigsegv/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libsigsegv.{dylib,a}} $(BUILD_DIST)/libsigsegv-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libsigsegv.mk Sign
	$(call SIGN,libsigsegv2,general.xml)
	
	# libsigsegv.mk Make .debs
	$(call PACK,libsigsegv2,DEB_LIBSIGSEGV_V)
	$(call PACK,libsigsegv-dev,DEB_LIBSIGSEGV_V)
	
	# libsigsegv.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsigsegv{2,-dev}

.PHONY: libsigsegv libsigsegv-package
