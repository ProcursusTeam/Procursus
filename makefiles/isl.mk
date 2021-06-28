ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += isl
ISL_VERSION := 0.23
DEB_ISL_V   ?= $(ISL_VERSION)

isl-setup: setup
	wget -q -np -P $(BUILD_SOURCE) http://isl.gforge.inria.fr/isl-$(ISL_VERSION).tar.xz
	$(call EXTRACT_TAR,isl-$(ISL_VERSION).tar.xz,isl-$(ISL_VERSION),isl)

ifneq ($(wildcard $(BUILD_WORK)/isl/.build_complete),)
isl:
	@echo "Using previously built isl."
else
isl: isl-setup libgmp10
	cd $(BUILD_WORK)/isl && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/isl
	+$(MAKE) -C $(BUILD_WORK)/isl install \
		DESTDIR="$(BUILD_STAGE)/isl"
	+$(MAKE) -C $(BUILD_WORK)/isl install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/isl/.build_complete
endif

isl-package: isl-stage
	# isl.mk Package Structure
	rm -rf $(BUILD_DIST)/libisl{23,-dev}
	mkdir -p $(BUILD_DIST)/libisl{23,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# isl.mk Prep libisl23
	cp -a $(BUILD_STAGE)/isl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libisl.23.dylib $(BUILD_DIST)/libisl23/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# isl.mk Prep libisl-dev
	cp -a $(BUILD_STAGE)/isl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libisl.23.dylib) $(BUILD_DIST)/libisl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/isl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libisl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
#   Don't do this after we add gdb (if we add gdb)
	rm -f $(BUILD_DIST)/libisl23/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libisl.23.dylib-gdb.py

	# isl.mk Sign
	$(call SIGN,libisl23,general.xml)

	# isl.mk Make .debs
	$(call PACK,libisl23,DEB_ISL_V)
	$(call PACK,libisl-dev,DEB_ISL_V)

	# isl.mk Build cleanup
	rm -rf $(BUILD_DIST)/libisl{23,-dev}

.PHONY: isl isl-package
