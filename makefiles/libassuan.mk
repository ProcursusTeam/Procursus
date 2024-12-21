ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS     += libassuan
LIBASSUAN_VERSION := 3.0.1
DEB_LIBASSUAN_V   ?= $(LIBASSUAN_VERSION)

libassuan-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://gnupg.org/ftp/gcrypt/libassuan/libassuan-$(LIBASSUAN_VERSION).tar.bz2{$(comma).sig})
	$(call PGP_VERIFY,libassuan-$(LIBASSUAN_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libassuan-$(LIBASSUAN_VERSION).tar.bz2,libassuan-$(LIBASSUAN_VERSION),libassuan)

ifneq ($(wildcard $(BUILD_WORK)/libassuan/.build_complete),)
libassuan:
	@echo "Using previously built libassuan."
else
libassuan: libassuan-setup libgpg-error
	cd $(BUILD_WORK)/libassuan && CFLAGS='-std=c89' ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-gpg-error-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/libassuan
	+$(MAKE) -C $(BUILD_WORK)/libassuan install \
		DESTDIR=$(BUILD_STAGE)/libassuan
	$(call AFTER_BUILD,copy)
endif

libassuan-package: libassuan-stage
	# libassuan.mk Package Structure
	rm -rf $(BUILD_DIST)/libassuan{-dev,9}
	mkdir -p $(BUILD_DIST)/libassuan{-dev,9}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libassuan.mk Prep libassuan9
	cp -a $(BUILD_STAGE)/libassuan/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libassuan.9.dylib $(BUILD_DIST)/libassuan9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libassuan.mk Prep libassuan-dev
	cp -a $(BUILD_STAGE)/libassuan/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libassuan.dylib} $(BUILD_DIST)/libassuan-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libassuan/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share,include} $(BUILD_DIST)/libassuan-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libassuan.mk Sign
	$(call SIGN,libassuan9,general.xml)
	$(call SIGN,libassuan-dev,general.xml)

	# libassuan.mk Make .debs
	$(call PACK,libassuan9,DEB_LIBASSUAN_V)
	$(call PACK,libassuan-dev,DEB_LIBASSUAN_V)

	# libassuan.mk Build cleanup
	rm -rf $(BUILD_DIST)/libassuan{-dev,9}

.PHONY: libassuan libassuan-package

