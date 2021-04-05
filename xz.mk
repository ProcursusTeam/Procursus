ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += xz
XZ_VERSION    := 5.2.5
DEB_XZ_V      ?= $(XZ_VERSION)-2

xz-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://tukaani.org/xz/xz-$(XZ_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,xz-$(XZ_VERSION).tar.xz)
	$(call EXTRACT_TAR,xz-$(XZ_VERSION).tar.xz,xz-$(XZ_VERSION),xz)
	mkdir -p $(BUILD_STAGE)/xz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/xz/.build_complete),)
xz:
	@echo "Using previously built xz."
else
xz: xz-setup gettext
	cd $(BUILD_WORK)/xz && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX) \
		--enable-threads \
		--disable-xzdec \
		--disable-lzmadec
	+$(MAKE) -C $(BUILD_WORK)/xz install \
		DESTDIR=$(BUILD_STAGE)/xz
	+$(MAKE) -C $(BUILD_WORK)/xz install \
		DESTDIR=$(BUILD_BASE)

	cd $(BUILD_WORK)/xz && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX) \
		--disable-shared \
		--disable-nls \
		--disable-encoders \
		--enable-small \
		--disable-threads \
		--disable-liblzma2-compat \
		--disable-lzmainfo \
		--disable-scripts \
		--disable-xz \
		--disable-lzma-links
	+$(MAKE) -C $(BUILD_WORK)/xz install \
		DESTDIR=$(BUILD_STAGE)/xz

ifneq ($(MEMO_ALT_PREFIX),)
	for bin in $(BUILD_STAGE)/xz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/bin/*; do \
		ln -s ../$(MEMO_ALT_PREFIX)/bin/$$(basename $$bin) $(BUILD_STAGE)/xz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$(basename $$bin); \
	done
endif # ($(MEMO_ALT_PREFIX),)
	touch $(BUILD_WORK)/xz/.build_complete
endif

xz-package: xz-stage
	# xz.mk Package Structure
	rm -rf $(BUILD_DIST)/xz{dec,-utils} $(BUILD_DIST)/liblzma{5,-dev}
	mkdir -p $(BUILD_DIST)/xz{dec,-utils}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,$(MEMO_ALT_PREFIX)/{bin,share/man/man1}} \
		$(BUILD_DIST)/liblzma{5,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib

	# xz.mk Prep xz-utils
	cp -a $(BUILD_STAGE)/xz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/!(*dec) $(BUILD_DIST)/xz-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/xz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/bin/!(*dec) $(BUILD_DIST)/xz-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/bin
	cp -a $(BUILD_STAGE)/xz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/share/man/man1/!(*dec.1) $(BUILD_DIST)/xz-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/share/man/man1

	# xz.mk Prep xzdec
	cp -a $(BUILD_STAGE)/xz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*dec $(BUILD_DIST)/xzdec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/xz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/bin/*dec $(BUILD_DIST)/xzdec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/bin
	cp -a $(BUILD_STAGE)/xz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/share/man/man1/*dec.1 $(BUILD_DIST)/xzdec/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/share/man/man1

	# xz.mk Prep liblzma5
	cp -a $(BUILD_STAGE)/xz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/liblzma.5.dylib $(BUILD_DIST)/liblzma5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib

	# xz.mk Prep liblzma-dev
	cp -a $(BUILD_STAGE)/xz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/!(liblzma.5.dylib) $(BUILD_DIST)/liblzma-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib
	cp -a $(BUILD_STAGE)/xz/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/include $(BUILD_DIST)/liblzma-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)

	# xz.mk Sign
	$(call SIGN,xz-utils,general.xml)
	$(call SIGN,xzdec,general.xml)
	$(call SIGN,liblzma5,general.xml)

	# xz.mk Make .debs
	$(call PACK,xz-utils,DEB_XZ_V)
	$(call PACK,xzdec,DEB_XZ_V)
	$(call PACK,liblzma5,DEB_XZ_V)
	$(call PACK,liblzma-dev,DEB_XZ_V)

	# xz.mk Build cleanup
	rm -rf $(BUILD_DIST)/xz{dec,-utils} $(BUILD_DIST)/liblzma{5,-dev}

.PHONY: xz xz-package
