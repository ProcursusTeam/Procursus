ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libkeccak
LIBKECCAK_VERSION := 1.3
DEB_LIBKECCAK_V   ?= $(LIBKECCAK_VERSION)

libkeccak-setup: setup
	$(call GITHUB_ARCHIVE,maandree,libkeccak,$(LIBKECCAK_VERSION),$(LIBKECCAK_VERSION))
	$(call EXTRACT_TAR,libkeccak-$(LIBKECCAK_VERSION).tar.gz,libkeccak-$(LIBKECCAK_VERSION),libkeccak)
	$(call DO_PATCH,libkeccak,libkeccak,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libkeccak/.build_complete),)
libkeccak:
	@echo "Using previously built libkeccak."
else
libkeccak: libkeccak-setup
	$(MAKE) -C $(BUILD_WORK)/libkeccak
	+$(MAKE) -C $(BUILD_WORK)/libkeccak install \
		DESTDIR=$(BUILD_STAGE)/libkeccak \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		MANPREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	rm -rf $(BUILD_STAGE)/libkeccak/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/licenses
	$(call AFTER_BUILD,copy)
endif

libkeccak-package: libkeccak-stage
	# libkeccak.mk Package Structure
	rm -rf $(BUILD_DIST)/libkeccak{1,-dev}
	mkdir -p $(BUILD_DIST)/libkeccak{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libkeccak.mk Prep libkeccak1
	cp -a $(BUILD_STAGE)/libkeccak/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkeccak.1{,.3}.dylib $(BUILD_DIST)/libkeccak1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libkeccak.mk Prep libkeccak-dev
	cp -a $(BUILD_STAGE)/libkeccak/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libkeccak-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libkeccak/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkeccak.{dylib,a} $(BUILD_DIST)/libkeccak-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libkeccak/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libkeccak-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libkeccak.mk Sign
	$(call SIGN,libkeccak1,general.xml)
	
	# libkeccak.mk Make .debs
	$(call PACK,libkeccak1,DEB_LIBKECCAK_V)
	$(call PACK,libkeccak-dev,DEB_LIBKECCAK_V)
	
	# libkeccak.mk Build cleanup
	rm -rf $(BUILD_DIST)/libkeccak{1,-dev}

.PHONY: libkeccak libkeccak-package
