ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libssh2
LIBSSH2_VERSION := 1.9.0
DEB_LIBSSH2_V   ?= $(LIBSSH2_VERSION)-2

libssh2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://libssh2.org/download/libssh2-$(LIBSSH2_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,libssh2-$(LIBSSH2_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,libssh2-$(LIBSSH2_VERSION).tar.gz,libssh2-$(LIBSSH2_VERSION),libssh2)

ifneq ($(wildcard $(BUILD_WORK)/libssh2/.build_complete),)
libssh2:
	@echo "Using previously built libssh2."
else
libssh2: libssh2-setup openssl
	find $(BUILD_BASE) -name "*.la" -type f -delete
	cd $(BUILD_WORK)/libssh2 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-debug \
		--disable-dependency-tracking \
		--with-libz
	+$(MAKE) -C $(BUILD_WORK)/libssh2
	+$(MAKE) -C $(BUILD_WORK)/libssh2 install \
		DESTDIR="$(BUILD_STAGE)/libssh2"
	+$(MAKE) -C $(BUILD_WORK)/libssh2 install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libssh2/.build_complete
endif

libssh2-package: libssh2-stage
	# libssh2.mk Package Structure
	rm -rf $(BUILD_DIST)/libssh2-{1,dev}
	mkdir -p $(BUILD_DIST)/libssh2-{1,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libssh2.mk Prep libssh2-1
	cp -a $(BUILD_STAGE)/libssh2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libssh2.1.dylib $(BUILD_DIST)/libssh2-1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libssh2.mk Prep libssh2-dev
	cp -a $(BUILD_STAGE)/libssh2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libssh2.{dylib,a}} $(BUILD_DIST)/libssh2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libssh2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libssh2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# libssh2.mk Sign
	$(call SIGN,libssh2-1,general.xml)

	# libssh2.mk Make .debs
	$(call PACK,libssh2-1,DEB_LIBSSH2_V)
	$(call PACK,libssh2-dev,DEB_LIBSSH2_V)

	# libssh2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libssh2-{1,dev}

.PHONY: libssh2 libssh2-package
