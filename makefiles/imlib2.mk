ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += imlib2
IMLIB2_VERSION := 1.7.1
DEB_IMLIB2_V   ?= $(IMLIB2_VERSION)

imlib2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.sourceforge.net/project/enlightenment/imlib2-src/$(IMLIB2_VERSION)/imlib2-$(IMLIB2_VERSION).tar.bz2
	$(call EXTRACT_TAR,imlib2-$(IMLIB2_VERSION).tar.bz2,imlib2-$(IMLIB2_VERSION),imlib2)

ifneq ($(wildcard $(BUILD_WORK)/imlib2/.build_complete),)
imlib2:
	@echo "Using previously built imlib2."
else
imlib2: imlib2-setup freetype libgif libjpeg-turbo libpng16 libtiff libx11 libxcb libxext
	cd $(BUILD_WORK)/imlib2 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-id3 \
		--enable-amd64=no
	+$(MAKE) -C $(BUILD_WORK)/imlib2
	+$(MAKE) -C $(BUILD_WORK)/imlib2 install \
		DESTDIR=$(BUILD_STAGE)/imlib2
	+$(MAKE) -C $(BUILD_WORK)/imlib2 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/imlib2/.build_complete
endif

imlib2-package: imlib2-stage
	# imlib2.mk Package Structure
	rm -rf $(BUILD_DIST)/libimlib2-{1,dev}
	mkdir -p $(BUILD_DIST)/libimlib2-1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libimlib2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# imlib2.mk Prep libimlib2-1
	cp -a $(BUILD_STAGE)/imlib2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libImlib2.1.dylib $(BUILD_DIST)/libimlib2-1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/imlib2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/imlib2 $(BUILD_DIST)/libimlib2-1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# imlib2.mk Prep libimlib2-dev
	cp -a $(BUILD_STAGE)/imlib2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libImlib2.1.dylib|imlib2) $(BUILD_DIST)/libimlib2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/imlib2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,include} $(BUILD_DIST)/libimlib2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# imlib2.mk Sign
	$(call SIGN,libimlib2-1,general.xml)
	$(call SIGN,libimlib2-dev,general.xml)

	# imlib2.mk Make .debs
	$(call PACK,libimlib2-1,DEB_IMLIB2_V)
	$(call PACK,libimlib2-dev,DEB_IMLIB2_V)

	# imlib2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libimlib2-{1,dev}

.PHONY: imlib2 imlib2-package
