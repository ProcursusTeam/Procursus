ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

# Also update the libraries' control files when a new major version releases

SUBPROJECTS   += libqrencode
LIBQRENCODE_VERSION := 4.1.1
LIBQRENCODE_MAJOR_VERSION := $(shell echo $(LIBQRENCODE_VERSION) | cut -d'.' -f1)
DEB_LIBQRENCODE_V   ?= $(LIBQRENCODE_VERSION)

libqrencode-setup: setup
	$(call GITHUB_ARCHIVE,fukuchi,libqrencode,$(LIBQRENCODE_VERSION),v$(LIBQRENCODE_VERSION))
	$(call EXTRACT_TAR,libqrencode-$(LIBQRENCODE_VERSION).tar.gz,libqrencode-$(LIBQRENCODE_VERSION),libqrencode)

ifneq ($(wildcard $(BUILD_WORK)/libqrencode/.build_complete),)
libqrencode:
	@echo "Using previously built libqrencode."
else
libqrencode: libqrencode-setup libpng16
	cd $(BUILD_WORK)/libqrencode && ./autogen.sh
	cd $(BUILD_WORK)/libqrencode && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libqrencode
	+$(MAKE) -C $(BUILD_WORK)/libqrencode install \
		DESTDIR=$(BUILD_STAGE)/libqrencode
	$(call AFTER_BUILD,copy)
endif

libqrencode-package: libqrencode-stage
	# libqrencode.mk Package Structure
	rm -rf $(BUILD_DIST)/qrencode \
		$(BUILD_DIST)/libqrencode{$(LIBQRENCODE_MAJOR_VERSION),-dev}
	mkdir -p $(BUILD_DIST)/qrencode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
		$(BUILD_DIST)/libqrencode{$(LIBQRENCODE_MAJOR_VERSION),-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libqrencode.mk Prep qrencode
	cp -a $(BUILD_STAGE)/libqrencode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/qrencode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libqrencode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/qrencode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	
	# libqrencode.mk Prep libqrencode$(LIBQRENCODE_MAJOR_VERSION)
	cp -a $(BUILD_STAGE)/libqrencode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libqrencode.$(LIBQRENCODE_MAJOR_VERSION).dylib $(BUILD_DIST)/libqrencode$(LIBQRENCODE_MAJOR_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libqrencode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libqrencode.la $(BUILD_DIST)/libqrencode$(LIBQRENCODE_MAJOR_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libqrencode.mk Prep libqrencode-dev
	cp -a $(BUILD_STAGE)/libqrencode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libqrencode-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libqrencode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libqrencode.{dylib,a} $(BUILD_DIST)/libqrencode-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libqrencode/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libqrencode-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libqrencode.mk Sign
	$(call SIGN,qrencode,general.xml)
	$(call SIGN,libqrencode$(LIBQRENCODE_MAJOR_VERSION),general.xml)

	# libqrencode.mk Make .debs
	$(call PACK,qrencode,DEB_LIBQRENCODE_V)
	$(call PACK,libqrencode$(LIBQRENCODE_MAJOR_VERSION),DEB_LIBQRENCODE_V)
	$(call PACK,libqrencode-dev,DEB_LIBQRENCODE_V)

	# libqrencode.mk Build cleanup
	rm -rf $(BUILD_DIST)/qrencode \
		$(BUILD_DIST)/libqrencode{$(LIBQRENCODE_MAJOR_VERSION),-dev}

.PHONY: libqrencode libqrencode-package
