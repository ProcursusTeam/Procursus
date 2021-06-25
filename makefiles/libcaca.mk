ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libcaca
LIBCACA_VERSION := 0.99.beta19
DEB_LIBCACA_V   ?= $(LIBCACA_VERSION)

libcaca-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://caca.zoy.org/files/libcaca/libcaca-$(LIBCACA_VERSION).tar.gz
	$(call EXTRACT_TAR,libcaca-$(LIBCACA_VERSION).tar.gz,libcaca-$(LIBCACA_VERSION),libcaca)

ifneq ($(wildcard $(BUILD_WORK)/libcaca/.build_complete),)
libcaca:
	@echo "Using previously built libcaca."
else
libcaca: libcaca-setup imlib2 slang2 ncurses
	cd $(BUILD_WORK)/libcaca && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-plugins \
		--disable-doc \
		--disable-java \
		--disable-csharp \
		--disable-ruby \
		--disable-python \
		ac_cv_header_endian_h=false
	+$(MAKE) -C $(BUILD_WORK)/libcaca
	+$(MAKE) -C $(BUILD_WORK)/libcaca install \
		DESTDIR=$(BUILD_STAGE)/libcaca
	+$(MAKE) -C $(BUILD_WORK)/libcaca install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libcaca/.build_complete
endif

libcaca-package: libcaca-stage
	# libcaca.mk Package Structure
	rm -rf $(BUILD_DIST)/libcaca{0,-dev} \
		$(BUILD_DIST)/caca-utils
	mkdir -p $(BUILD_DIST)/libcaca0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libcaca-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib,share/man/man1} \
		$(BUILD_DIST)/caca-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

	# libcaca.mk Prep caca-utils
	cp -a $(BUILD_STAGE)/libcaca/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/caca-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libcaca/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/!(caca-config.1) $(BUILD_DIST)/caca-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/libcaca/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/caca-config $(BUILD_DIST)/caca-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# libcaca.mk Prep libcaca0
	cp -a $(BUILD_STAGE)/libcaca/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcaca{,++}.0.dylib $(BUILD_DIST)/libcaca0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libcaca/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/caca $(BUILD_DIST)/libcaca0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	rm -f $(BUILD_DIST)/libcaca0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/caca/*.a

	# libcaca.mk Prep libcaca-dev
	cp -a $(BUILD_STAGE)/libcaca/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libcaca{,++}.{a,dylib},pkgconfig} $(BUILD_DIST)/libcaca-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libcaca/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libcaca-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libcaca/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/caca-config $(BUILD_DIST)/libcaca-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/libcaca/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/caca-config.1 $(BUILD_DIST)/libcaca-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# libcaca.mk Sign
	$(call SIGN,caca-utils,general.xml)
	$(call SIGN,libcaca0,general.xml)

	# libcaca.mk Make .debs
	$(call PACK,caca-utils,DEB_LIBCACA_V)
	$(call PACK,libcaca0,DEB_LIBCACA_V)
	$(call PACK,libcaca-dev,DEB_LIBCACA_V)

	# libcaca.mk Build cleanup
	rm -rf $(BUILD_DIST)/libcaca{0,-dev} \
		$(BUILD_DIST)/caca-utils

.PHONY: libcaca libcaca-package
