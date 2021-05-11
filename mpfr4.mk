ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += mpfr4
MPFR4_VERSION := 4.1.0
DEB_MPFR4_V   ?= $(MPFR4_VERSION)

mpfr4-setup: setup
	wget -q -np -P $(BUILD_SOURCE) https://ftp.gnu.org/gnu/mpfr/mpfr-$(MPFR4_VERSION).tar.xz
	$(call EXTRACT_TAR,mpfr-$(MPFR4_VERSION).tar.xz,mpfr-$(MPFR4_VERSION),mpfr4)

ifneq ($(wildcard $(BUILD_WORK)/mpfr4/.build_complete),)
mpfr4:
	@echo "Using previously built mpfr4."
else
mpfr4: mpfr4-setup libgmp10
	cd $(BUILD_WORK)/mpfr4 && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/mpfr4
	+$(MAKE) -C $(BUILD_WORK)/mpfr4 install \
		DESTDIR="$(BUILD_STAGE)/mpfr4"
	+$(MAKE) -C $(BUILD_WORK)/mpfr4 install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/mpfr4/.build_complete
endif

mpfr4-package: mpfr4-stage
	# mpfr4.mk Package Structure
	rm -rf $(BUILD_DIST)/libmpfr{6,-dev}
	mkdir -p $(BUILD_DIST)/libmpfr{6,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mpfr4.mk Prep libmpfr6
	cp -a $(BUILD_STAGE)/mpfr4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmpfr.6.dylib $(BUILD_DIST)/libmpfr6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mpfr4.mk Prep libmpfr-dev
	cp -a $(BUILD_STAGE)/mpfr4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libmpfr.6.dylib) $(BUILD_DIST)/libmpfr-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/mpfr4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libmpfr-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# mpfr4.mk Sign
	$(call SIGN,libmpfr6,general.xml)

	# mpfr4.mk Make .debs
	$(call PACK,libmpfr6,DEB_MPFR4_V)
	$(call PACK,libmpfr-dev,DEB_MPFR4_V)

	# mpfr4.mk Build cleanup
	rm -rf $(BUILD_DIST)/libmpfr{6,-dev}

.PHONY: mpfr4 mpfr4-package
