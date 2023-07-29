ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

GMP_CF700_VERSION   := 6.2.1
DEB_GMP_CF700_V     ?= $(GMP_CF700_VERSION)-3

libgmp10_CF700-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://gmplib.org/download/gmp/gmp-$(GMP_CF700_VERSION).tar.xz{$(comma).sig})
	$(call PGP_VERIFY,gmp-$(GMP_CF700_VERSION).tar.xz)
	$(call EXTRACT_TAR,gmp-$(GMP_CF700_VERSION).tar.xz,gmp-$(GMP_CF700_VERSION),libgmp10)

ifneq ($(wildcard $(BUILD_WORK)/libgmp10/.build_complete),)
libgmp10_CF700:
	@echo "Using previously built libgmp10."
else
libgmp10_CF700: libgmp10_CF700-setup
#	Disable assembly because of
#	https://github.com/ProcursusTeam/Procursus/issues/750
	cd $(BUILD_WORK)/libgmp10 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-cxx \
		--disable-assembly \
		CC_FOR_BUILD='$(shell command -v cc) $(CFLAGS_FOR_BUILD)' \
		CPP_FOR_BUILD='$(shell command -v cc) -E $(CPPFLAGS_FOR_BUILD)'
	+$(MAKE) -C $(BUILD_WORK)/libgmp10
	+$(MAKE) -C $(BUILD_WORK)/libgmp10 install \
		DESTDIR=$(BUILD_STAGE)/libgmp10
	$(call AFTER_BUILD,copy)
endif

libgmp10_CF700-package:: DEB_GMP_V ?= $(DEB_GMP_CF700_V)
libgmp10_CF700-package: libgmp10_CF700-stage
	# libgmp10.mk Package Structure
	rm -rf $(BUILD_DIST)/libgmp{10,xx4ldbl,-dev}
	mkdir -p $(BUILD_DIST)/libgmp{10,xx4ldbl,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libgmp10.mk Prep libgmp10
	cp -a $(BUILD_STAGE)/libgmp10/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgmp.10.dylib $(BUILD_DIST)/libgmp10/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libgmp10.mk Prep libgmpxx4ldbl
	cp -a $(BUILD_STAGE)/libgmp10/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgmpxx.4.dylib $(BUILD_DIST)/libgmpxx4ldbl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libgmp10.mk Prep libgmp-dev
	cp -a $(BUILD_STAGE)/libgmp10/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libgmp.10.dylib|libgmpxx.4.dylib) $(BUILD_DIST)/libgmp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libgmp10/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libgmp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libgmp10.mk Sign
	$(call SIGN,libgmp10,general.xml)
	$(call SIGN,libgmpxx4ldbl,general.xml)

	# libgmp10.mk Make .debs
	$(call PACK,libgmp10,DEB_GMP_V)
	$(call PACK,libgmpxx4ldbl,DEB_GMP_V)
	$(call PACK,libgmp-dev,DEB_GMP_V)

	# libgmp10.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgmp{10,xx4ldbl,-dev}

.PHONY: libgmp10_CF700 libgmp10_CF700-package
