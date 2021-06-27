ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += libksba
KSBA_VERSION  := 1.5.0
DEB_KSBA_V    ?= $(KSBA_VERSION)-1

libksba-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://gnupg.org/ftp/gcrypt/libksba/libksba-$(KSBA_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,libksba-$(KSBA_VERSION).tar.bz2)
	$(call EXTRACT_TAR,libksba-$(KSBA_VERSION).tar.bz2,libksba-$(KSBA_VERSION),libksba)

ifneq ($(wildcard $(BUILD_WORK)/libksba/.build_complete),)
libksba:
	@echo "Using previously built libksba."
else
libksba: libksba-setup libgpg-error
	cd $(BUILD_WORK)/libksba && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-gpg-error-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/libksba
	+$(MAKE) -C $(BUILD_WORK)/libksba install \
		DESTDIR=$(BUILD_STAGE)/libksba
	+$(MAKE) -C $(BUILD_WORK)/libksba install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libksba/.build_complete
endif

libksba-package: libksba-stage
	# libksba.mk Package Structure
	rm -rf $(BUILD_DIST)/libksba{8,-dev}
	mkdir -p $(BUILD_DIST)/libksba{8,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libksba.mk Prep libksba8
	cp -a $(BUILD_STAGE)/libksba/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libksba.8.dylib $(BUILD_DIST)/libksba8/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libksba.mk Prep libksba-dev
	cp -a $(BUILD_STAGE)/libksba/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libksba.dylib} $(BUILD_DIST)/libksba-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libksba/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,include,share} $(BUILD_DIST)/libksba-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libksba.mk Sign
	$(call SIGN,libksba8,general.xml)
	$(call SIGN,libksba-dev,general.xml)

	# libksba.mk Make .debs
	$(call PACK,libksba8,DEB_KSBA_V)
	$(call PACK,libksba-dev,DEB_KSBA_V)

	# libksba.mk Build cleanup
	rm -rf $(BUILD_DIST)/libksba{8,-dev}

.PHONY: libksba libksba-package
