ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += pcre2
PCRE2_VERSION := 10.36
DEB_PCRE2_V   ?= $(PCRE2_VERSION)

pcre2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.pcre.org/pub/pcre/pcre2-$(PCRE2_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,pcre2-$(PCRE2_VERSION).tar.bz2)
	$(call EXTRACT_TAR,pcre2-$(PCRE2_VERSION).tar.bz2,pcre2-$(PCRE2_VERSION),pcre2)

ifneq ($(wildcard $(BUILD_WORK)/pcre2/.build_complete),)
pcre2:
	@echo "Using previously built pcre2."
else
pcre2: pcre2-setup readline
	cd $(BUILD_WORK)/pcre2 && unset MACOSX_DEPLOYMENT_TARGET && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking \
		--enable-jit \
		--enable-pcre2-16 \
		--enable-pcre2-32 \
		--enable-pcre2grep-libz \
		--enable-pcre2grep-libbz2 \
	+$(MAKE) -C $(BUILD_WORK)/pcre2
	+$(MAKE) -C $(BUILD_WORK)/pcre2 install \
		DESTDIR=$(BUILD_STAGE)/pcre2
	+$(MAKE) -C $(BUILD_WORK)/pcre2 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/pcre2/.build_complete
endif

pcre2-package: pcre2-stage
	# pcre2.mk Package Structure
	rm -rf $(BUILD_DIST)/libpcre2-{{8,16,32}-0,dev,posix2} $(BUILD_DIST)/pcre2-utils
	mkdir -p $(BUILD_DIST)/libpcre2-{{8,16,32}-0,posix2}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libpcre2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib,share/man/man1} \
		$(BUILD_DIST)/pcre2-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

	# pcre2.mk Prep pcre2-utils
	cp -a $(BUILD_STAGE)/pcre2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/!(pcre2-config) $(BUILD_DIST)/pcre2-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/pcre2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/!(pcre2-config.1) $(BUILD_DIST)/pcre2-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# pcre2.mk Prep libpcre2-{8,16,32}-0
	for ver in {8,16,32}; do \
		cp -a $(BUILD_STAGE)/pcre2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpcre2-$${ver}.0.dylib $(BUILD_DIST)/libpcre2-$${ver}-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib; \
	done

	# pcre2.mk Prep libpcre2-posix2
	cp -a $(BUILD_STAGE)/pcre2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpcre2-posix.2.dylib $(BUILD_DIST)/libpcre2-posix2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# pcre2.mk Prep libpcre2-dev
	cp -a $(BUILD_STAGE)/pcre2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(*8.0*|*16.0*|*32.0*|*posix.2*) $(BUILD_DIST)/libpcre2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/pcre2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pcre2-config $(BUILD_DIST)/libpcre2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/pcre2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/pcre2-config.1 $(BUILD_DIST)/libpcre2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/pcre2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libpcre2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	cp -a $(BUILD_STAGE)/pcre2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libpcre2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# pcre2.mk Sign
	$(call SIGN,libpcre2-8-0,general.xml)
	$(call SIGN,libpcre2-16-0,general.xml)
	$(call SIGN,libpcre2-32-0,general.xml)
	$(call SIGN,libpcre2-posix2,general.xml)
	$(call SIGN,pcre2-utils,general.xml)

	# pcre2.mk Make .debs
	$(call PACK,libpcre2-8-0,DEB_PCRE2_V)
	$(call PACK,libpcre2-16-0,DEB_PCRE2_V)
	$(call PACK,libpcre2-32-0,DEB_PCRE2_V)
	$(call PACK,libpcre2-posix2,DEB_PCRE2_V)
	$(call PACK,libpcre2-dev,DEB_PCRE2_V)
	$(call PACK,pcre2-utils,DEB_PCRE2_V)

	# pcre2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpcre2-{{8,16,32}-0,dev,posix2} $(BUILD_DIST)/pcre2-utils

.PHONY: pcre2 pcre2-package
